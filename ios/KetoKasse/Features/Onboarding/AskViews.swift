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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draftName = ""
    @State private var draftRole: FamilyRole = .man

    private var canAdd: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canProceed: Bool {
        answers.canContinue(from: .household) || canAdd
    }

    var body: some View {
        OnboardingChrome(
            title: "Hvem bor her?",
            ctaTitle: "FORTSETT",
            ctaEnabled: canProceed,
            action: continueAfterFlushingDraft
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if !answers.family.isEmpty {
                    memberStrip
                }
                rolePicker
                OnboardingTextField(placeholder: "Navn", text: $draftName, onSubmit: addDraft)
                Button(action: addDraft) {
                    Text("Legg til")
                        .font(KKFont.cta)
                        .tracking(KKFont.ctaTracking)
                        .foregroundStyle(KKColor.forest)
                }
                .buttonStyle(.plain)
                .disabled(!canAdd)
                .opacity(canAdd ? 1 : 0.45)
                .accessibilityLabel("Legg til")
            }
            .padding(.top, 8)
        }
    }

    private var memberStrip: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 140), spacing: 8, alignment: .leading)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(answers.family) { member in
                MemberChip(member: member) {
                    removeMember(member)
                }
            }
        }
    }

    private var rolePicker: some View {
        HStack(spacing: 8) {
            ForEach(FamilyRole.allCases) { role in
                SelectChip(title: role.title, isSelected: draftRole == role) {
                    draftRole = role
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: draftRole)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rolle")
    }

    private func addDraft() {
        guard canAdd else { return }
        mutateFamily {
            answers.addFamilyMember(name: draftName, role: draftRole)
        }
        draftName = ""
    }

    private func removeMember(_ member: FamilyMember) {
        mutateFamily {
            answers.removeFamilyMember(member)
        }
    }

    private func continueAfterFlushingDraft() {
        addDraft()
        onContinue()
    }

    private func mutateFamily(_ update: () -> Void) {
        if reduceMotion {
            update()
        } else {
            withAnimation(.snappy) {
                update()
            }
        }
    }
}

private struct MemberChip: View {
    var member: FamilyMember
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            FamilyRoleAvatar(role: member.role)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
            Text(member.name)
                .font(KKFont.cta)
                .foregroundStyle(KKColor.ink)
                .lineLimit(1)
                .accessibilityLabel("\(member.role.title), \(member.name)")
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(KKFont.cta)
                    .foregroundStyle(KKColor.muted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fjern \(member.name)")
        }
        .padding(.leading, 8)
        .background(KKColor.white, in: Capsule())
        .overlay {
            Capsule()
                .stroke(KKColor.line, lineWidth: 1)
        }
    }
}

private struct FamilyRoleAvatar: View {
    var role: FamilyRole

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
            PersonMark(role: role)
        }
        .clipShape(Circle())
    }

    private var fill: Color {
        switch role {
        case .man: KKColor.mint
        case .woman: KKColor.peach
        case .child: KKColor.sky
        case .baby: KKColor.gold
        }
    }
}

private struct PersonMark: View {
    var role: FamilyRole

    var body: some View {
        VStack(spacing: 1.5) {
            ZStack {
                if role == .woman {
                    Capsule()
                        .fill(KKColor.forest)
                        .frame(width: head + 5, height: head + 7)
                        .offset(y: 4)
                }
                Circle()
                    .fill(KKColor.forest)
                    .frame(width: head, height: head)
                if role == .man || role == .child {
                    Capsule()
                        .fill(KKColor.forest)
                        .frame(width: head + 1, height: 5)
                        .offset(y: -head * 0.38)
                }
            }
            Capsule()
                .fill(KKColor.forest)
                .frame(width: bodyWidth, height: bodyHeight)
        }
        .offset(y: role == .baby ? 2 : 1)
    }

    private var head: CGFloat {
        switch role {
        case .man, .woman: 13
        case .child: 14
        case .baby: 16
        }
    }

    private var bodyWidth: CGFloat {
        switch role {
        case .man: 16
        case .woman: 14
        case .child: 13
        case .baby: 12
        }
    }

    private var bodyHeight: CGFloat {
        switch role {
        case .man: 12
        case .woman: 13
        case .child: 10
        case .baby: 8
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
    var onSubmit: (() -> Void)? = nil

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
            .submitLabel(.done)
            .onSubmit { onSubmit?() }
            .padding(16)
            .background(KKColor.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KKColor.line, lineWidth: 1)
            )
    }
}

#Preview("Household") {
    NavigationStack {
        HouseholdAskView(answers: OnboardingState(), onContinue: {})
    }
}
