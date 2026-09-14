import SwiftUI

struct GoalAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    var body: some View {
        OnboardingChrome(
            title: "Hva er viktigst?",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .goal),
            action: onContinue
        ) {
            VStack(spacing: 10) {
                ForEach(OnboardingGoal.allCases) { goal in
                    SelectRow(title: goal.title, isSelected: answers.goal == goal) {
                        answers.goal = goal
                    }
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.goal)
        }
    }
}

struct AllergiesAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    var body: some View {
        OnboardingChrome(
            title: "Allergier",
            support: "Velg det som gjelder, eller Ingen.",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .allergies),
            action: onContinue
        ) {
            VStack(spacing: 10) {
                SelectRow(title: "Ingen", isSelected: answers.noAllergiesSelected) {
                    answers.selectNoAllergies()
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(AllergyCategory.allCases) { category in
                        SelectChip(title: category.title, isSelected: answers.allergySelected(category)) {
                            answers.toggleAllergy(category)
                        }
                    }
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.allergies)
        }
    }
}

struct AddressAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    private let floorColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        OnboardingChrome(
            title: "Hvor bor du?",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .address),
            action: onContinue
        ) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(HousingKind.allCases) { kind in
                    SelectRow(title: kind.title, isSelected: answers.housing == kind) {
                        answers.housing = kind
                        if !kind.needsFloor {
                            answers.floor = nil
                        }
                    }
                }
                if answers.housing?.needsFloor == true {
                    Text("Etasje")
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.ink)
                        .padding(.top, 8)
                    LazyVGrid(columns: floorColumns, spacing: 8) {
                        ForEach(OnboardingState.floors, id: \.self) { floor in
                            SelectChip(title: "\(floor)", isSelected: answers.floor == floor) {
                                answers.floor = floor
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.housing)
            .animation(.snappy, value: answers.floor)
        }
    }
}

struct HouseholdAskView: View {
    @Bindable var answers: OnboardingState
    var onContinue: () -> Void

    var body: some View {
        OnboardingChrome(
            title: "Hvem bor her?",
            ctaTitle: "FORTSETT",
            ctaEnabled: answers.canContinue(from: .household),
            action: onContinue
        ) {
            VStack(alignment: .leading, spacing: 12) {
                OnboardingTextField(placeholder: "Ola", text: $answers.name)
                personalityRow
                ForEach($answers.family) { $member in
                    familyRow($member)
                }
                Button(action: answers.addFamilyMember) {
                    Text("Legg til familie")
                        .font(KKFont.cta)
                        .tracking(KKFont.ctaTracking)
                        .foregroundStyle(KKColor.forest)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.top, 8)
            .animation(.snappy, value: answers.personality)
            .animation(.snappy, value: answers.family.count)
        }
    }

    private var personalityRow: some View {
        HStack(spacing: 12) {
            ForEach(Personality.allCases) { option in
                personalityChip(option)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Personlighet")
    }

    private func personalityChip(_ option: Personality) -> some View {
        let isSelected = answers.personality == option
        return Button {
            answers.personality = option
        } label: {
            Image(systemName: option.symbol)
                .font(.title2)
                .foregroundStyle(isSelected ? KKColor.lime : KKColor.forest)
                .frame(width: 56, height: 56)
                .background(chipFill(option), in: Circle())
                .overlay {
                    Circle()
                        .stroke(isSelected ? KKColor.forest : KKColor.line, lineWidth: isSelected ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func chipFill(_ option: Personality) -> Color {
        switch option {
        case .crate: KKColor.sky
        case .leaf: KKColor.mint
        case .carrot: KKColor.peach
        case .flame: KKColor.gold
        }
    }

    private func familyRow(_ member: Binding<FamilyMember>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                OnboardingTextField(placeholder: "Navn", text: member.name)
                Button {
                    answers.removeFamilyMember(member.wrappedValue)
                } label: {
                    Image(systemName: "xmark")
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.muted)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fjern")
            }
            HStack(spacing: 8) {
                ForEach(FamilyRole.allCases) { role in
                    SelectChip(title: role.title, isSelected: member.wrappedValue.role == role) {
                        member.wrappedValue.role = role
                    }
                }
            }
        }
    }
}

private struct SelectRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
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
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SelectChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
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
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OnboardingTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        if #available(iOS 18.0, *) {
            field.writingToolsBehavior(.disabled)
        } else {
            field
        }
    }

    private var field: some View {
        TextField(placeholder, text: $text)
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
