import Foundation
import Observation
import Supabase

enum AuthPhase: Equatable {
    case unknown
    case signedOut
    case signedIn
}

enum AuthFlowError: Equatable {
    case invalidEmail
    case rateLimited
    case expiredLink
    case missingConfig
    case message(String)
}

@MainActor
@Observable
final class AuthService {
    private(set) var phase: AuthPhase = .unknown
    private(set) var session: Session?
    var pendingInviteToken: String?
    var linkError: AuthFlowError?
    var needsHandoff = false

    private static let emailRateLimitUntilKey = "kk.auth.emailRateLimitUntil"
    private(set) var emailRateLimitUntil: Date?

    init() {
        let raw = UserDefaults.standard.double(forKey: Self.emailRateLimitUntilKey)
        if raw > Date().timeIntervalSince1970 {
            emailRateLimitUntil = Date(timeIntervalSince1970: raw)
        }
    }

    func emailLockRemaining(at now: Date = .now) -> TimeInterval {
        guard let emailRateLimitUntil else { return 0 }
        return max(0, emailRateLimitUntil.timeIntervalSince(now))
    }

    var userID: UUID? { session?.user.id }
    var email: String? { session?.user.email }

    private var listener: Task<Void, Never>?

    func startListening() {
        guard listener == nil else { return }
        guard let client = KKSupabase.client else {
            phase = .signedOut
            return
        }
        listener = Task { [weak self] in
            for await (_, session) in client.auth.authStateChanges {
                guard let self, !Task.isCancelled else { return }
                let previous = self.phase
                self.session = session
                self.phase = session == nil ? .signedOut : .signedIn
                if session != nil {
                    self.linkError = nil
                    if previous == .signedOut {
                        self.needsHandoff = true
                    }
                } else {
                    self.needsHandoff = false
                }
            }
        }
    }

    func sendMagicLink(email: String) async throws {
        guard emailLockRemaining() == 0 else { throw AuthFlowError.rateLimited }
        guard let client = KKSupabase.client else { throw AuthFlowError.missingConfig }
        do {
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: InviteURL.authCallback
            )
        } catch {
            let mapped = Self.mapSendError(error)
            if mapped == .rateLimited {
                markEmailRateLimited()
            }
            throw mapped
        }
    }

    func markEmailRateLimited(for interval: TimeInterval = 3600) {
        let until = Date().addingTimeInterval(interval)
        emailRateLimitUntil = until
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: Self.emailRateLimitUntilKey)
    }

    func clearEmailRateLimitIfExpired(at now: Date = .now) {
        guard let emailRateLimitUntil, emailRateLimitUntil <= now else { return }
        self.emailRateLimitUntil = nil
        UserDefaults.standard.removeObject(forKey: Self.emailRateLimitUntilKey)
    }

    func handleOpenURL(_ url: URL) async {
        if let token = InviteURL.token(from: url) {
            pendingInviteToken = token
            return
        }
        guard InviteURL.isAuthCallback(url) || url.scheme == InviteURL.scheme else { return }
        guard let client = KKSupabase.client else {
            linkError = .missingConfig
            return
        }
        do {
            let wasSignedIn = phase == .signedIn
            try await client.auth.session(from: url)
            linkError = nil
            if !wasSignedIn {
                needsHandoff = true
            }
        } catch {
            linkError = .expiredLink
        }
    }

    func acceptHandoff() {
        needsHandoff = false
    }

    func signOut() async {
        pendingInviteToken = nil
        linkError = nil
        needsHandoff = false
        try? await KKSupabase.client?.auth.signOut()
        session = nil
        phase = .signedOut
    }

    func clearPendingInvite() {
        pendingInviteToken = nil
    }

    static func isValidEmail(_ raw: String) -> Bool {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return false }
        let host = parts[1]
        return host.contains(".") && !host.hasPrefix(".") && !host.hasSuffix(".")
    }

    static func mapSendError(_ error: Error) -> AuthFlowError {
        if let flow = error as? AuthFlowError { return flow }
        if let auth = error as? AuthError, auth.errorCode == .overEmailSendRateLimit {
            return .rateLimited
        }
        let text = error.localizedDescription.lowercased()
        let dumped = String(describing: error).lowercased()
        if dumped.contains("over_email_send_rate_limit") || text.contains("429") {
            return .rateLimited
        }
        if text.contains("rate") || dumped.contains("rate") {
            return .rateLimited
        }
        return .message(error.localizedDescription)
    }
}

extension AuthFlowError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidEmail: "Skriv inn en gyldig e-post."
        case .rateLimited: "For mange e-poster denne timen. Vent og prøv igjen."
        case .expiredLink: "Lenken er utløpt."
        case .missingConfig: "Mangler tilkobling til konto."
        case .message(let text): text
        }
    }
}

extension AuthService {
    static var previewSignedOut: AuthService {
        let service = AuthService()
        service.phase = .signedOut
        return service
    }
}
