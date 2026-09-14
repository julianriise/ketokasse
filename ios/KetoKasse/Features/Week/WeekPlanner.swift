import Foundation

enum PlanWeekday: Int, CaseIterable, Identifiable, Codable, Sendable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday: "Man"
        case .tuesday: "Tir"
        case .wednesday: "Ons"
        case .thursday: "Tor"
        case .friday: "Fre"
        case .saturday: "Lør"
        case .sunday: "Søn"
        }
    }

    static func on(_ date: Date, calendar: Calendar = .current) -> PlanWeekday {
        let sundayIndexed = calendar.component(.weekday, from: date)
        let mondayIndexed = (sundayIndexed + 5) % 7 + 1
        return PlanWeekday(rawValue: mondayIndexed)!
    }
}

struct WeekPlan: Equatable, Codable, Sendable {
    static let dayCount = 7
    static let dinnerCount = 5

    var seed: UInt64
    var slots: [String?]

    var filledTitles: [String] {
        slots.compactMap { $0 }
    }

    var filledCount: Int { filledTitles.count }

    func title(on day: PlanWeekday) -> String? {
        slots[day.rawValue - 1]
    }

    func dish(on day: PlanWeekday) -> Dish? {
        title(on: day).flatMap(DishPool.dish(titled:))
    }
}

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum WeekPlanner {
    static func isoWeekSeed(for date: Date, calendar: Calendar = .current) -> UInt64 {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        let week = iso.component(.weekOfYear, from: date)
        let year = iso.component(.yearForWeekOfYear, from: date)
        return UInt64(year) &* 100 &+ UInt64(week)
    }

    static func isoWeekKey(for date: Date, calendar: Calendar = .current) -> String {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        let week = iso.component(.weekOfYear, from: date)
        let year = iso.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    static func mix(weekSeed: UInt64, generation: UInt64) -> UInt64 {
        weekSeed &* 1_000_003 &+ generation
    }

    static func generate(
        seed: UInt64,
        avoiding previousTitles: Set<String>,
        pool: [Dish] = DishPool.all
    ) -> WeekPlan {
        var rng = SplitMix64(seed: seed)
        let dishes = pickDishes(pool: pool, avoiding: previousTitles, rng: &rng)
        let slots = place(dishes, rng: &rng)
        return WeekPlan(seed: seed, slots: slots.map { $0?.title })
    }

    static func proteinsAreValid(_ slots: [Dish?]) -> Bool {
        guard slots.count == WeekPlan.dayCount else { return false }
        guard slots.compactMap({ $0 }).count == WeekPlan.dinnerCount else { return false }
        for index in 0..<(WeekPlan.dayCount - 1) {
            guard let a = slots[index], let b = slots[index + 1] else { continue }
            if a.protein == b.protein {
                return false
            }
        }
        return true
    }

    private static func pickDishes(
        pool: [Dish],
        avoiding previousTitles: Set<String>,
        rng: inout SplitMix64
    ) -> [Dish] {
        let pizza = pool.first { $0.title == DishPool.pizzaTitle } ?? DishPool.pizza
        let rest = pool.filter { $0.title != pizza.title }
        let fresh = shuffled(rest.filter { !previousTitles.contains($0.title) }, rng: &rng)
        let stale = shuffled(rest.filter { previousTitles.contains($0.title) }, rng: &rng)
        let ranked = fresh + stale

        var four: [Dish] = []
        var chickenCount = 1
        for dish in ranked where four.count < 4 {
            if dish.protein == pizza.protein && chickenCount >= 4 {
                continue
            }
            four.append(dish)
            if dish.protein == pizza.protein {
                chickenCount += 1
            }
        }
        for dish in ranked where four.count < 4 {
            if !four.contains(dish) {
                four.append(dish)
            }
        }
        return [pizza] + four
    }

    private static func place(_ dishes: [Dish], rng: inout SplitMix64) -> [Dish?] {
        let empties = shuffled(emptyPairs(), rng: &rng)
        for _ in 0..<200 {
            let perm = shuffled(dishes, rng: &rng)
            for empty in empties {
                let slots = build(perm, empty: empty)
                if proteinsAreValid(slots) {
                    return slots
                }
            }
        }
        for perm in permutations(dishes) {
            for empty in emptyPairs() {
                let slots = build(perm, empty: empty)
                if proteinsAreValid(slots) {
                    return slots
                }
            }
        }
        return build(dishes, empty: (2, 5))
    }

    private static func build(_ dishes: [Dish], empty: (Int, Int)) -> [Dish?] {
        var slots: [Dish?] = Array(repeating: nil, count: WeekPlan.dayCount)
        var dishIndex = 0
        for day in 0..<WeekPlan.dayCount {
            if day == empty.0 || day == empty.1 { continue }
            slots[day] = dishes[dishIndex]
            dishIndex += 1
        }
        return slots
    }

    private static func emptyPairs() -> [(Int, Int)] {
        var pairs: [(Int, Int)] = []
        for a in 0..<WeekPlan.dayCount {
            for b in (a + 1)..<WeekPlan.dayCount {
                pairs.append((a, b))
            }
        }
        return pairs
    }

    private static func shuffled<T>(_ items: [T], rng: inout SplitMix64) -> [T] {
        var items = items
        var i = items.count
        while i > 1 {
            i -= 1
            let j = Int(rng.next() % UInt64(i + 1))
            items.swapAt(i, j)
        }
        return items
    }

    private static func permutations<T>(_ items: [T]) -> [[T]] {
        var items = items
        var result: [[T]] = []
        permute(&items, start: 0, into: &result)
        return result
    }

    private static func permute<T>(_ items: inout [T], start: Int, into result: inout [[T]]) {
        if start == items.count {
            result.append(items)
            return
        }
        for index in start..<items.count {
            items.swapAt(start, index)
            permute(&items, start: start + 1, into: &result)
            items.swapAt(start, index)
        }
    }
}
