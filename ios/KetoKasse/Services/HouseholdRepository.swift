import Foundation
import Observation
import Supabase

struct HouseholdInvite: Equatable, Sendable {
    var token: String
    var expiresAt: Date
}

struct CookDraft: Equatable, Sendable {
    var dishTitle: String
    var dayIndex: Int
    var pointsAwarded: Int
}

enum HouseholdError: LocalizedError {
    case missingConfig
    case notReady
    case inviteInvalid
    case offline
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingConfig: "Mangler tilkobling til konto."
        case .notReady: "Husholdningen er ikke klar."
        case .inviteInvalid: "Invitasjonen er brukt eller utløpt. Be om en ny QR."
        case .offline: "Koble til nett og prøv igjen."
        case .message(let text): text
        }
    }
}

@MainActor
@Observable
final class HouseholdRepository {
    var householdID: UUID?
    var name = "Familie"
    var invite: HouseholdInvite?
    var remotePoints: Int?
    var remoteWeekSlots: [String?]?
    var isPreparing = false
    var lastError: String?

    private var channel: RealtimeChannelV2?
    private var realtimeTasks: [Task<Void, Never>] = []

    func reset() {
        stopRealtime()
        householdID = nil
        name = "Familie"
        invite = nil
        remotePoints = nil
        remoteWeekSlots = nil
        isPreparing = false
        lastError = nil
    }

    func ensure() async {
        isPreparing = true
        defer { isPreparing = false }
        guard let client = KKSupabase.client else {
            lastError = "Mangler tilkobling til konto."
            return
        }
        do {
            try await Self.waitForSession(client)
            let response = try await client.rpc("ensure_own_household").execute()
            let id = try Self.decodeUUID(from: response.data)
            householdID = id
            await refreshHouseholdSoft(id)
            lastError = nil
        } catch {
            lastError = Self.mapEnsure(error)
        }
    }

    func deleteAccount() async throws {
        guard let client = KKSupabase.client else { throw HouseholdError.missingConfig }
        try await Self.waitForSession(client)
        try await client.rpc("delete_own_account").execute()
        reset()
    }

    func liveInvite() async -> HouseholdInvite? {
        guard let client = KKSupabase.client, let householdID else { return nil }
        do {
            let response = try await client.from("household_invites")
                .select("token,expires_at")
                .eq("household_id", value: householdID)
                .is("redeemed_at", value: nil)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
            let invite = try Self.decodeInvite(from: response.data)
            guard invite.expiresAt > Date() else { return nil }
            return invite
        } catch {
            return nil
        }
    }

    func shareInvite() async throws -> HouseholdInvite {
        if let live = await liveInvite() {
            invite = live
            return live
        }
        return try await createInvite()
    }

    func createInvite() async throws -> HouseholdInvite {
        guard let client = KKSupabase.client else { throw HouseholdError.missingConfig }
        do {
            let response = try await client.rpc("create_invite").execute()
            let invite = try Self.decodeInvite(from: response.data)
            self.invite = invite
            return invite
        } catch {
            if let live = await liveInvite() {
                invite = live
                return live
            }
            throw Self.mapInvite(error)
        }
    }

    func redeem(_ token: String) async throws {
        guard let client = KKSupabase.client else { throw HouseholdError.missingConfig }
        do {
            let id: UUID = try await client
                .rpc("redeem_invite", params: RedeemParams(inviteToken: token))
                .execute()
                .value
            householdID = id
            try await refreshHousehold(id)
        } catch {
            throw Self.mapRedeem(error)
        }
    }

    func fetchWeekSlots() async -> [String?]? {
        guard let client = KKSupabase.client, let householdID else { return nil }
        do {
            let rows: [WeekPlanRow] = try await client.from("week_plans")
                .select("household_id, week_start, slots")
                .eq("household_id", value: householdID)
                .eq("week_start", value: WeekDates.mondayString())
                .limit(1)
                .execute()
                .value
            guard let row = rows.first, row.slots.count == WeekPlan.dayCount else { return nil }
            remoteWeekSlots = row.slots
            return row.slots
        } catch {
            return nil
        }
    }

    func upsertWeekPlan(_ slots: [String?]) async {
        guard let client = KKSupabase.client, let householdID else { return }
        let payload = WeekPlanUpsert(
            householdId: householdID,
            weekStart: WeekDates.mondayString(),
            slots: slots,
            updatedBy: try? await client.auth.session.user.id
        )
        do {
            try await client.from("week_plans")
                .upsert(payload, onConflict: "household_id,week_start")
                .execute()
        } catch {
            return
        }
    }

    func fetchPoints() async -> Int? {
        guard let client = KKSupabase.client, let householdID else { return nil }
        do {
            let rows: [HouseholdRow] = try await client.from("households")
                .select("id, name, points_total")
                .eq("id", value: householdID)
                .limit(1)
                .execute()
                .value
            guard let row = rows.first else { return nil }
            name = row.name
            remotePoints = row.pointsTotal
            return row.pointsTotal
        } catch {
            return nil
        }
    }

    func pushPoints(_ total: Int, cook: CookDraft?) async {
        guard let client = KKSupabase.client, let householdID else { return }
        let userID = try? await client.auth.session.user.id
        if let cook, let userID {
            let event = CookEventInsert(
                householdId: householdID,
                cookedBy: userID,
                dishTitle: cook.dishTitle,
                dayIndex: cook.dayIndex,
                pointsAwarded: max(0, cook.pointsAwarded)
            )
            _ = try? await client.from("cook_events").insert(event).execute()
        }
        let update = PointsUpdate(pointsTotal: max(0, total))
        _ = try? await client.from("households")
            .update(update)
            .eq("id", value: householdID)
            .execute()
        remotePoints = max(0, total)
    }

    func startRealtime() async {
        stopRealtime()
        guard let client = KKSupabase.client, let householdID else { return }
        let channel = client.channel("household-\(householdID.uuidString)")
        self.channel = channel
        let decoder = PostgrestClient.Configuration.jsonDecoder
        let weekStream = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "week_plans",
            filter: .eq("household_id", value: householdID)
        )
        let houseStream = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "households",
            filter: .eq("id", value: householdID)
        )
        realtimeTasks.append(Task { [weak self] in
            for await update in weekStream {
                guard let self, !Task.isCancelled else { return }
                if let row = try? update.decodeRecord(as: WeekPlanRow.self, decoder: decoder),
                   row.slots.count == WeekPlan.dayCount {
                    self.remoteWeekSlots = row.slots
                }
            }
        })
        realtimeTasks.append(Task { [weak self] in
            for await update in houseStream {
                guard let self, !Task.isCancelled else { return }
                if let row = try? update.decodeRecord(as: HouseholdRow.self, decoder: decoder) {
                    self.name = row.name
                    self.remotePoints = row.pointsTotal
                }
            }
        })
        try? await channel.subscribeWithError()
    }

    func stopRealtime() {
        realtimeTasks.forEach { $0.cancel() }
        realtimeTasks = []
        let channel = self.channel
        self.channel = nil
        guard let channel else { return }
        Task {
            await channel.unsubscribe()
        }
    }

    private func refreshHouseholdSoft(_ id: UUID) async {
        try? await refreshHousehold(id)
    }

    private func refreshHousehold(_ id: UUID) async throws {
        guard let client = KKSupabase.client else { throw HouseholdError.missingConfig }
        let rows: [HouseholdRow] = try await client.from("households")
            .select("id, name, points_total")
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        if let row = rows.first {
            name = row.name
            remotePoints = row.pointsTotal
        }
    }

    private static func waitForSession(_ client: SupabaseClient) async throws {
        for attempt in 0..<8 {
            if let session = try? await client.auth.session, !session.isExpired {
                return
            }
            if attempt == 7 {
                _ = try await client.auth.session
                return
            }
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    private static func decodeUUID(from data: Data) throws -> UUID {
        let raw = try JSONSerialization.jsonObject(with: data)
        if let id = uuid(from: raw) { return id }
        throw HouseholdError.message("Kunne ikke hente husholdning.")
    }

    private static func uuid(from raw: Any) -> UUID? {
        if let string = raw as? String {
            return UUID(uuidString: string)
        }
        if let dict = raw as? [String: Any] {
            for key in ["ensure_own_household", "id"] {
                if let string = dict[key] as? String, let id = UUID(uuidString: string) {
                    return id
                }
            }
        }
        if let list = raw as? [Any], let first = list.first {
            return uuid(from: first)
        }
        return nil
    }

    private static func decodeInvite(from data: Data) throws -> HouseholdInvite {
        let raw = try JSONSerialization.jsonObject(with: data)
        let dict: [String: Any]
        if let list = raw as? [[String: Any]] {
            guard let first = list.first else {
                throw HouseholdError.message("Kunne ikke lage QR-kode.")
            }
            dict = first
        } else if let object = raw as? [String: Any] {
            dict = object
        } else {
            throw HouseholdError.message("Kunne ikke lage QR-kode.")
        }
        guard let token = dict["token"] as? String, !token.isEmpty else {
            throw HouseholdError.message("Kunne ikke lage QR-kode.")
        }
        let expiry = parseTimestamp(dict["expires_at"] ?? dict["expiresAt"])
            ?? Date().addingTimeInterval(7 * 24 * 3600)
        return HouseholdInvite(token: token, expiresAt: expiry)
    }

    private static func parseTimestamp(_ raw: Any?) -> Date? {
        guard let raw else { return nil }
        if let date = raw as? Date { return date }
        guard let string = raw as? String else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSxxx",
            "yyyy-MM-dd'T'HH:mm:ssxxx",
            "yyyy-MM-dd HH:mm:ss.SSSSSSxxxxx",
            "yyyy-MM-dd HH:mm:ssxxxxx",
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }

    private static func mapInvite(_ error: Error) -> HouseholdError {
        if let existing = error as? HouseholdError { return existing }
        if (error as NSError).domain == NSURLErrorDomain { return .offline }
        let dumped = String(describing: error).lowercased()
        let text = error.localizedDescription
        if dumped.contains("notconnected") || dumped.contains("offline") || dumped.contains("network") {
            return .offline
        }
        if text.isEmpty { return .message("Kunne ikke lage QR-kode.") }
        return .message(text)
    }

    private static func mapEnsure(_ error: Error) -> String {
        if let existing = error as? HouseholdError {
            return existing.errorDescription ?? "Kunne ikke hente husholdning."
        }
        if (error as NSError).domain == NSURLErrorDomain {
            return HouseholdError.offline.errorDescription ?? "Koble til nett og prøv igjen."
        }
        let dumped = String(describing: error).lowercased()
        if dumped.contains("not authenticated") || dumped.contains("session") {
            return "Logg inn på nytt."
        }
        if dumped.contains("notconnected") || dumped.contains("offline") || dumped.contains("network") {
            return HouseholdError.offline.errorDescription ?? "Koble til nett og prøv igjen."
        }
        let text = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "Kunne ikke hente husholdning." }
        return text
    }

    private static func mapRedeem(_ error: Error) -> HouseholdError {
        if let existing = error as? HouseholdError { return existing }
        let text = error.localizedDescription.lowercased()
        let dumped = String(describing: error).lowercased()
        if text.contains("offline") || dumped.contains("notconnected") || dumped.contains("network") {
            return .offline
        }
        if text.contains("invite") || dumped.contains("expired") || dumped.contains("invalid") {
            return .inviteInvalid
        }
        if (error as NSError).domain == NSURLErrorDomain { return .offline }
        return .inviteInvalid
    }
}

extension HouseholdRepository {
    static var preview: HouseholdRepository {
        let repo = HouseholdRepository()
        repo.householdID = UUID()
        repo.name = "Familie"
        repo.remotePoints = 40
        repo.invite = HouseholdInvite(
            token: "previewtokenpreviewtokenpreviewto",
            expiresAt: Date().addingTimeInterval(7 * 24 * 3600)
        )
        return repo
    }
}

enum WeekDates {
    static func mondayString(for date: Date = Date(), calendar: Calendar = .current) -> String {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        let start = iso.date(from: iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        let formatter = DateFormatter()
        formatter.calendar = iso
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: start)
    }
}

private struct RedeemParams: Encodable {
    var inviteToken: String
}

private struct HouseholdRow: Decodable {
    var id: UUID
    var name: String
    var pointsTotal: Int
}

private struct WeekPlanRow: Decodable {
    var householdId: UUID?
    var weekStart: String
    var slots: [String?]
}

private struct WeekPlanUpsert: Encodable {
    var householdId: UUID
    var weekStart: String
    var slots: [String?]
    var updatedBy: UUID?
}

private struct CookEventInsert: Encodable {
    var householdId: UUID
    var cookedBy: UUID
    var dishTitle: String
    var dayIndex: Int
    var pointsAwarded: Int
}

private struct PointsUpdate: Encodable {
    var pointsTotal: Int
}
