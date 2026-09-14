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

enum OnboardingGoal: String, CaseIterable, Identifiable, Hashable {
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

enum AllergyCategory: String, CaseIterable, Identifiable, Hashable {
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

enum AllergyAnswer: Equatable, Hashable {
    case noAllergies
    case listed(Set<AllergyCategory>)
}

enum HousingKind: String, CaseIterable, Identifiable, Hashable {
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

enum Personality: String, CaseIterable, Identifiable, Hashable {
    case crate
    case leaf
    case carrot
    case flame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crate: "Kasse"
        case .leaf: "Blad"
        case .carrot: "Gulrot"
        case .flame: "Flamme"
        }
    }

    var symbol: String {
        switch self {
        case .crate: "shippingbox.fill"
        case .leaf: "leaf.fill"
        case .carrot: "carrot.fill"
        case .flame: "flame.fill"
        }
    }
}

enum FamilyRole: String, CaseIterable, Identifiable, Hashable {
    case adult
    case child
    case baby

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adult: "Voksen"
        case .child: "Barn"
        case .baby: "Baby"
        }
    }
}

struct FamilyMember: Identifiable, Equatable, Hashable {
    var id = UUID()
    var name = ""
    var role: FamilyRole = .adult
}

enum MealPlan: String, CaseIterable, Identifiable, Hashable {
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
    var goal: OnboardingGoal?
    var allergies: AllergyAnswer?
    var housing: HousingKind?
    var floor: Int?
    var name = ""
    var personality: Personality?
    var family: [FamilyMember] = []
    var plan: MealPlan?

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

    func addFamilyMember() {
        family.append(FamilyMember())
    }

    func removeFamilyMember(_ member: FamilyMember) {
        family.removeAll { $0.id == member.id }
    }

    func canContinue(from step: OnboardingStep) -> Bool {
        switch step {
        case .cooking:
            true
        case .goal:
            goal != nil
        case .allergies:
            switch allergies {
            case .noAllergies:
                true
            case .listed(let set):
                !set.isEmpty
            case nil:
                false
            }
        case .address:
            guard let housing else { return false }
            return !housing.needsFloor || floor != nil
        case .household:
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && personality != nil
        case .pricing:
            plan != nil
        }
    }
}
