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

struct OnboardingChrome<Content: View>: View {
    var title: String
    var support: String? = nil
    var ctaTitle: String
    var ctaEnabled: Bool = true
    var action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(KKFont.headline)
                    .tracking(KKFont.headlineTracking)
                    .foregroundStyle(KKColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let support {
                    Text(support)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            GetStartedButton(title: ctaTitle, isEnabled: ctaEnabled, action: action)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(KKColor.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(KKColor.white, for: .navigationBar)
    }
}

#Preview {
    OnboardingFlow(answers: OnboardingState(), onFinished: {})
}
