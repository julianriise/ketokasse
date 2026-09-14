import SwiftUI

enum OnboardingStep: Int, Hashable, CaseIterable {
    case cooking = 1
    case goal
    case allergies
    case address
    case household
    case pricing

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }
}

enum OnboardingGoal: String, CaseIterable, Identifiable, Hashable, Codable {
    case loseWeight
    case getStronger
    case everydayEnergy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .loseWeight: "Gå ned i vekt"
        case .getStronger: "Bli sterkere"
        case .everydayEnergy: "Overskudd i hverdagen"
        }
    }
}

enum AllergyCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case nuts
    case citrus
    case gluten
    case egg
    case dairy
    case shellfish
    case soy
    case sesame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nuts: "Nøtter"
        case .citrus: "Sitrusfrukt"
        case .gluten: "Gluten"
        case .egg: "Egg"
        case .dairy: "Meieri"
        case .shellfish: "Skalldyr"
        case .soy: "Soya"
        case .sesame: "Sesam"
        }
    }
}

enum AllergyAnswer: Equatable, Hashable, Codable {
    case noAllergies
    case listed(Set<AllergyCategory>)
}

enum HousingKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case apartment
    case duplex
    case house

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apartment: "Leilighet"
        case .duplex: "Tomannsbolig"
        case .house: "Rekkehus/enebolig"
        }
    }

    var needsFloor: Bool { self != .house }
}

enum FamilyRole: String, CaseIterable, Identifiable, Hashable, Codable {
    case man
    case woman
    case child
    case baby

    var id: String { rawValue }

    var title: String {
        switch self {
        case .man: "Mann"
        case .woman: "Dame"
        case .child: "Barn"
        case .baby: "Baby"
        }
    }
}

struct FamilyMember: Identifiable, Equatable, Hashable, Codable {
    var id = UUID()
    var name: String
    var role: FamilyRole
}

enum MealPlan: String, CaseIterable, Identifiable, Hashable, Codable {
    case standard
    case farm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Standard kvalitet"
        case .farm: "Gårdskvalitet"
        }
    }

    var priceLabel: String {
        switch self {
        case .standard: "kr 1 490,–"
        case .farm: "kr 2 290,–"
        }
    }
}

@MainActor
@Observable
final class OnboardingState {
    private static let defaultsKey = "kk.onboardingAnswers"

    private let defaults: UserDefaults

    var goal: OnboardingGoal? {
        didSet { persist() }
    }
    var allergies: AllergyAnswer? {
        didSet { persist() }
    }
    var housing: HousingKind? {
        didSet { persist() }
    }
    var floor: Int? {
        didSet { persist() }
    }
    var family: [FamilyMember] = [] {
        didSet { persist() }
    }
    var plan: MealPlan? {
        didSet { persist() }
    }

    var primaryName: String {
        family.first?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static let floors = Array(1...8)

    var noAllergiesSelected: Bool {
        switch allergies {
        case .noAllergies:
            true
        case .listed:
            false
        case nil:
            false
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let snapshot = Self.load(from: defaults) {
            goal = snapshot.goal
            allergies = snapshot.allergies
            housing = snapshot.housing
            floor = snapshot.floor
            family = snapshot.family
            plan = snapshot.plan
        }
    }

    func allergySelected(_ category: AllergyCategory) -> Bool {
        if case .listed(let set) = allergies {
            return set.contains(category)
        }
        return false
    }

    func selectNoAllergies() {
        allergies = .noAllergies
    }

    func toggleAllergy(_ category: AllergyCategory) {
        switch allergies {
        case nil:
            allergies = .listed([category])
        case .noAllergies:
            allergies = .listed([category])
        case .listed(let set):
            var next = set
            if next.contains(category) {
                next.remove(category)
                allergies = next.isEmpty ? nil : .listed(next)
            } else {
                next.insert(category)
                allergies = .listed(next)
            }
        }
    }

    func addFamilyMember(name: String, role: FamilyRole) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        family.append(FamilyMember(name: trimmed, role: role))
    }

    func removeFamilyMember(_ member: FamilyMember) {
        family.removeAll { $0.id == member.id }
    }

    func reset() {
        goal = nil
        allergies = nil
        housing = nil
        floor = nil
        family = []
        plan = nil
        defaults.removeObject(forKey: Self.defaultsKey)
    }

    func canContinue(from step: OnboardingStep) -> Bool {
        switch step {
        case .cooking:
            return true
        case .goal:
            return goal != nil
        case .allergies:
            switch allergies {
            case .noAllergies:
                return true
            case .listed(let set):
                return !set.isEmpty
            case nil:
                return false
            }
        case .address:
            guard let housing else { return false }
            return !housing.needsFloor || floor != nil
        case .household:
            return family.contains {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        case .pricing:
            return plan != nil
        }
    }

    private func persist() {
        let snapshot = Snapshot(
            goal: goal,
            allergies: allergies,
            housing: housing,
            floor: floor,
            family: family,
            plan: plan
        )
        defaults.set(try? JSONEncoder().encode(snapshot), forKey: Self.defaultsKey)
    }

    private static func load(from defaults: UserDefaults) -> Snapshot? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private struct Snapshot: Codable, Equatable {
        var goal: OnboardingGoal?
        var allergies: AllergyAnswer?
        var housing: HousingKind?
        var floor: Int?
        var family: [FamilyMember]
        var plan: MealPlan?
    }
}
