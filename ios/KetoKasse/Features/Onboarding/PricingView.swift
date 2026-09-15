import SwiftUI

struct PricingView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void = {}

    var body: some View {
        OnboardingChrome(
            step: .pricing,
            bubbleText: "Sånn! Velg kvalitet.",
            pose: .celebrate,
            support: "5 måltider for 2. Samme kutt. Bedre råvarer, ikke mer i lomma.",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .pricing),
            action: onContinue
        ) {
            VStack(spacing: 12) {
                ForEach(MealPlan.allCases) { plan in
                    planCard(plan)
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.plan)
        }
    }

    private func planCard(_ plan: MealPlan) -> some View {
        let isSelected = answers.plan == plan
        return Button {
            answers.plan = plan
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.title)
                    .font(KKFont.body)
                    .foregroundStyle(isSelected ? KKColor.lime : KKColor.ink)
                Text(plan.priceLabel)
                    .font(KKFont.headline)
                    .tracking(KKFont.headlineTracking)
                    .foregroundStyle(isSelected ? KKColor.lime : KKColor.forest)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? KKColor.forest : KKColor.mint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? KKColor.forest : KKColor.line, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.title), \(plan.priceLabel)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        PricingView(answers: OnboardingState(), onContinue: {})
    }
}
