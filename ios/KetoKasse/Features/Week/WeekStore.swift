import Foundation
import Observation

@MainActor
@Observable
final class WeekStore {
    private static let defaultsKey = "kk.weekStore"

    private let defaults: UserDefaults
    private(set) var plan: WeekPlan
    private var calendarWeekKey: String
    private var generation: UInt64
    private var lastFilledTitles: [String]
    var remote: HouseholdRepository?

    var todayDish: Dish? {
        plan.dish(on: .on(Date()))
    }

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        let currentKey = WeekPlanner.isoWeekKey(for: now)
        if let snapshot = Self.load(from: defaults), snapshot.isValid() {
            calendarWeekKey = snapshot.calendarWeekKey
            generation = snapshot.generation
            lastFilledTitles = snapshot.lastFilledTitles
            plan = WeekPlan(seed: snapshot.seed, slots: snapshot.slots)
            if snapshot.calendarWeekKey != currentKey {
                rotate(now: now, previous: snapshot.slots.compactMap { $0 })
            }
        } else {
            calendarWeekKey = currentKey
            generation = 0
            lastFilledTitles = []
            let seed = WeekPlanner.isoWeekSeed(for: now)
            plan = WeekPlanner.generate(seed: seed, avoiding: [])
            persist()
        }
    }

    func simulateNewWeek(now: Date = Date()) {
        lastFilledTitles = plan.filledTitles
        generation &+= 1
        calendarWeekKey = WeekPlanner.isoWeekKey(for: now)
        let seed = WeekPlanner.mix(weekSeed: WeekPlanner.isoWeekSeed(for: now), generation: generation)
        plan = WeekPlanner.generate(seed: seed, avoiding: Set(lastFilledTitles))
        persist()
    }

    func moveSlot(from source: Int, to target: Int) {
        guard source != target,
              plan.slots.indices.contains(source),
              plan.slots.indices.contains(target) else { return }
        var next = plan
        let item = next.slots.remove(at: source)
        next.slots.insert(item, at: target)
        guard next != plan else { return }
        plan = next
        persist()
    }

    private func rotate(now: Date, previous: [String]) {
        lastFilledTitles = previous
        generation = 0
        calendarWeekKey = WeekPlanner.isoWeekKey(for: now)
        let seed = WeekPlanner.isoWeekSeed(for: now)
        plan = WeekPlanner.generate(seed: seed, avoiding: Set(previous))
        persist()
    }

    func applyRemoteSlots(_ slots: [String?]) {
        guard Self.isValidSlots(slots) else { return }
        guard slots != plan.slots else { return }
        plan = WeekPlan(seed: plan.seed, slots: slots)
        persistLocal()
    }

    func syncRemote() async {
        guard let remote else { return }
        if let slots = await remote.fetchWeekSlots(), Self.isValidSlots(slots) {
            applyRemoteSlots(slots)
        } else {
            await remote.upsertWeekPlan(plan.slots)
        }
    }

    private func persist() {
        persistLocal()
        pushRemote()
    }

    private func persistLocal() {
        let snapshot = Snapshot(
            calendarWeekKey: calendarWeekKey,
            generation: generation,
            lastFilledTitles: lastFilledTitles,
            seed: plan.seed,
            slots: plan.slots
        )
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }

    private func pushRemote() {
        guard let remote else { return }
        let slots = plan.slots
        Task {
            await remote.upsertWeekPlan(slots)
        }
    }

    private static func isValidSlots(_ slots: [String?]) -> Bool {
        guard slots.count == WeekPlan.dayCount else { return false }
        let filled = slots.compactMap { $0 }
        guard filled.count == WeekPlan.dinnerCount else { return false }
        return filled.allSatisfy { DishPool.dish(titled: $0) != nil }
    }

    private static func load(from defaults: UserDefaults) -> Snapshot? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private struct Snapshot: Codable {
        var calendarWeekKey: String
        var generation: UInt64
        var lastFilledTitles: [String]
        var seed: UInt64
        var slots: [String?]

        func isValid() -> Bool {
            guard slots.count == WeekPlan.dayCount else { return false }
            let filled = slots.compactMap { $0 }
            guard filled.count == WeekPlan.dinnerCount else { return false }
            guard filled.allSatisfy({ DishPool.dish(titled: $0) != nil }) else { return false }
            return true
        }
    }
}
