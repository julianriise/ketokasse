import SwiftUI

struct OnboardingFlow: View {
    @Bindable var answers: OnboardingState
    var onFinished: () -> Void = {}

    @State private var path: [OnboardingStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(onContinue: { push(.cooking) })
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: OnboardingStep.self) { step in
                    stepView(step)
                }
        }
        .tint(KKColor.forest)
        .background(KKColor.white.ignoresSafeArea())
    }

    @ViewBuilder
    private func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .cooking:
            CookingFunView(onContinue: { goNext(from: .cooking) })
        case .goal:
            GoalAskView(answers: answers, onContinue: { goNext(from: .goal) })
        case .allergies:
            AllergiesAskView(answers: answers, onContinue: { goNext(from: .allergies) })
        case .address:
            AddressAskView(answers: answers, onContinue: { goNext(from: .address) })
        case .household:
            HouseholdAskView(answers: answers, onContinue: { goNext(from: .household) })
        case .pricing:
            PricingView(answers: answers, onFinished: { goNext(from: .pricing) })
        }
    }

    private func push(_ step: OnboardingStep) {
        path.append(step)
    }

    private func goNext(from step: OnboardingStep) {
        guard answers.canContinue(from: step) else { return }
        if let next = step.next {
            push(next)
        } else {
            onFinished()
        }
    }
}

#Preview {
    OnboardingFlow(answers: OnboardingState(), onFinished: {})
}
