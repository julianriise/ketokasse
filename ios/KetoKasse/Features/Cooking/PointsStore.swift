import Foundation
import Observation

@MainActor
@Observable
final class PointsStore {
    private static let defaultsKey = "kk.pointsStore"

    private let defaults: UserDefaults
    private(set) var total: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let snapshot = Self.load(from: defaults) {
            total = max(0, snapshot.total)
        } else {
            total = 0
        }
    }

    func add(_ amount: Int) {
        guard amount > 0 else { return }
        total += amount
        persist()
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
