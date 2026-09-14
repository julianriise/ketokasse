import SwiftUI

struct NameAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    var body: some View {
        OnboardingChrome(
            title: "Hva skal vi kalle deg?",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .name),
            action: onContinue
        ) {
            nameField
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var nameField: some View {
        if #available(iOS 18.0, *) {
            baseNameField.writingToolsBehavior(.disabled)
        } else {
            baseNameField
        }
    }

    private var baseNameField: some View {
        TextField("Ola", text: $answers.name)
            .font(KKFont.body)
            .foregroundStyle(KKColor.ink)
            .textInputAutocapitalization(.words)
            .submitLabel(.continue)
            .padding(16)
            .background(KKColor.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KKColor.line, lineWidth: 1)
            )
    }
}

struct GoalAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    var body: some View {
        OnboardingChrome(
            title: "Hva er viktigst for deg?",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .goal),
            action: onContinue
        ) {
            VStack(spacing: 10) {
                ForEach(OnboardingGoal.allCases) { goal in
                    goalRow(goal)
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.goal)
        }
    }

    private func goalRow(_ goal: OnboardingGoal) -> some View {
        let isSelected = answers.goal == goal
        return Button {
            answers.goal = goal
        } label: {
            HStack {
                Text(goal.title)
                    .font(KKFont.body)
                    .foregroundStyle(isSelected ? KKColor.lime : KKColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.lime)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
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
        .accessibilityLabel(goal.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct DeliveryDayAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        OnboardingChrome(
            title: "Når vil du ha kassen?",
            support: "Levering på ettermiddagen. Velg en ukedag.",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .deliveryDay),
            action: onContinue
        ) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(DeliveryWeekday.allCases) { day in
                    dayChip(day)
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.deliveryWeekday)
        }
    }

    private func dayChip(_ day: DeliveryWeekday) -> some View {
        let isSelected = answers.deliveryWeekday == day
        return Button {
            answers.deliveryWeekday = day
        } label: {
            Text(day.shortLabel)
                .font(KKFont.cta)
                .foregroundStyle(isSelected ? KKColor.lime : KKColor.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
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
        .accessibilityLabel(day.shortLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
