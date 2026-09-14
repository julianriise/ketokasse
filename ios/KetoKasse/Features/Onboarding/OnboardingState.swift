import SwiftUI

enum OnboardingStep: Int, Hashable, CaseIterable {
    case cooking = 1
    case mealPlan
    case name
    case goal
    case deliveryDay
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

enum DeliveryWeekday: Int, CaseIterable, Identifiable, Hashable {
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
    var name = ""
    var goal: OnboardingGoal?
    var deliveryWeekday: DeliveryWeekday?
    var plan: MealPlan?

    func canContinue(from step: OnboardingStep) -> Bool {
        switch step {
        case .cooking, .mealPlan:
            true
        case .name:
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .goal:
            goal != nil
        case .deliveryDay:
            deliveryWeekday != nil
        case .pricing:
            plan != nil
        }
    }
}
