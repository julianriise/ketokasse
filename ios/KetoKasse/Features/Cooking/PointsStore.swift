import Foundation
import Observation

@MainActor
@Observable
final class PointsStore {
    private static let defaultsKey = "kk.pointsStore"

    private let defaults: UserDefaults
    private(set) var total: Int
    var remote: HouseholdRepository?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let snapshot = Self.load(from: defaults) {
            total = max(0, snapshot.total)
        } else {
            total = 0
        }
    }

    func add(_ amount: Int, cook: CookDraft? = nil) {
        if amount > 0 {
            total += amount
            persist()
        } else if cook == nil {
            return
        }
        pushRemote(cook: cook)
    }

    func applyRemote(_ value: Int) {
        let next = max(0, value)
        guard next != total else { return }
        total = next
        persist()
    }

    func syncRemote() async {
        guard let remote else { return }
        if let value = await remote.fetchPoints() {
            applyRemote(value)
        }
    }

    private func pushRemote(cook: CookDraft?) {
        guard let remote else { return }
        let snapshot = total
        Task {
            await remote.pushPoints(snapshot, cook: cook)
        }
    }

    private func persist() {
        let snapshot = Snapshot(total: total)
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }

    private static func load(from defaults: UserDefaults) -> Snapshot? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private struct Snapshot: Codable, Equatable {
        var total: Int
    }
}
