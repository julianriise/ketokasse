import SwiftUI

struct SettingsView: View {
    @Bindable var answers: OnboardingState
    var onRestart: () -> Void
    var onSignOut: () -> Void = {}
    var onDeleteAccount: () -> Void = {}

    @State private var draftName = ""
    @State private var draftRole: FamilyRole = .man
    @State private var confirmRestart = false
    @State private var confirmDelete = false
    @State private var showShare = false

    private var canAddMember: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                shareSection
                householdSection
                goalSection
                allergiesSection
                housingSection
                planSection
                appSection
            }
            .tint(KKColor.forest)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KKColor.white, for: .navigationBar)
            .confirmationDialog("Start på nytt?", isPresented: $confirmRestart, titleVisibility: .visible) {
                Button("Start på nytt", role: .destructive, action: onRestart)
            }
            .confirmationDialog("Slette kontoen?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Slett kontoen", role: .destructive, action: onDeleteAccount)
            } message: {
                Text("Er du sikker? E-post, husholdning og poeng blir borte. Ny magisk lenke kan ta opptil en time.")
            }
            .sheet(isPresented: $showShare) {
                ShareHouseholdView()
            }
        }
        .tint(KKColor.forest)
        .background(KKColor.white.ignoresSafeArea())
    }

    private var shareSection: some View {
        Section {
            Button {
                showShare = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(KKFont.cta)
                    Text("Del med partner")
                        .font(KKFont.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.muted)
                }
                .foregroundStyle(KKColor.forest)
            }
            .accessibilityLabel("Del med partner")
        } header: {
            sectionHeader("Deling")
        }
    }

    private var householdSection: some View {
        Section {
            ForEach(answers.family) { member in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.role.title)
                            .font(KKFont.cta)
                            .foregroundStyle(KKColor.muted)
                        Text(member.name)
                            .font(KKFont.body)
                            .foregroundStyle(KKColor.ink)
                    }
                    Spacer()
                    Button("Fjern", role: .destructive) {
                        answers.removeFamilyMember(member)
                    }
                    .font(KKFont.body)
                    .accessibilityLabel("Fjern \(member.name)")
                }
            }
            nameField
            Picker(selection: $draftRole) {
                ForEach(FamilyRole.allCases) { role in
                    Text(role.title)
                        .font(KKFont.body)
                        .tag(role)
                }
            } label: {
                Text("Rolle")
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.ink)
            }
            .pickerStyle(.segmented)
            Button("Legg til", action: addDraft)
                .font(KKFont.cta)
                .disabled(!canAddMember)
                .accessibilityLabel("Legg til")
        } header: {
            sectionHeader("Husstand")
        }
    }

    private var goalSection: some View {
        Section {
            ForEach(OnboardingGoal.allCases) { goal in
                SettingCheckRow(title: goal.title, isSelected: answers.goal == goal) {
                    answers.goal = goal
                }
            }
        } header: {
            sectionHeader("Mål")
        }
    }

    private var allergiesSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { answers.noAllergiesSelected },
                set: { on in
                    if on {
                        answers.selectNoAllergies()
                    } else if answers.noAllergiesSelected {
                        answers.allergies = nil
                    }
                }
            )) {
                Text("Ingen")
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.ink)
            }
            ForEach(AllergyCategory.allCases) { category in
                Toggle(isOn: Binding(
                    get: { answers.allergySelected(category) },
                    set: { _ in answers.toggleAllergy(category) }
                )) {
                    Text(category.title)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.ink)
                }
            }
        } header: {
            sectionHeader("Allergier")
        }
    }

    private var housingSection: some View {
        Section {
            ForEach(HousingKind.allCases) { kind in
                SettingCheckRow(title: kind.title, isSelected: answers.housing == kind) {
                    answers.housing = kind
                    if !kind.needsFloor {
                        answers.floor = nil
                    }
                }
            }
            if answers.housing?.needsFloor == true {
                Picker(selection: Binding(
                    get: { answers.floor },
                    set: { answers.floor = $0 }
                )) {
                    ForEach(OnboardingState.floors, id: \.self) { floor in
                        Text("\(floor)")
                            .font(KKFont.body)
                            .tag(Optional(floor))
                    }
                } label: {
                    Text("Etasje")
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.ink)
                }
            }
        } header: {
            sectionHeader("Bolig")
        }
    }

    private var planSection: some View {
        Section {
            ForEach(MealPlan.allCases) { plan in
                SettingCheckRow(
                    title: plan.title,
                    subtitle: plan.priceLabel,
                    isSelected: answers.plan == plan
                ) {
                    answers.plan = plan
                }
            }
        } header: {
            sectionHeader("Plan")
        } footer: {
            Text("5 måltider for 2. Samme kutt. Bedre råvarer, ikke mer i lomma.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
        }
    }

    private var appSection: some View {
        Section {
            Button("Logg ut") {
                onSignOut()
            }
            .font(KKFont.body)
            .foregroundStyle(KKColor.ink)
            Button("Start på nytt", role: .destructive) {
                confirmRestart = true
            }
            .font(KKFont.body)
            Button("Slett konto", role: .destructive) {
                confirmDelete = true
            }
            .font(KKFont.body)
        } header: {
            sectionHeader("App")
        }
    }

    private var nameField: some View {
        Group {
            if #available(iOS 18.0, *) {
                nameTextField.writingToolsBehavior(.disabled)
            } else {
                nameTextField
            }
        }
    }

    private var nameTextField: some View {
        TextField("Navn", text: $draftName)
            .font(KKFont.body)
            .foregroundStyle(KKColor.ink)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .onSubmit(addDraft)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(KKFont.cta)
            .foregroundStyle(KKColor.muted)
            .textCase(nil)
    }

    private func addDraft() {
        guard canAddMember else { return }
        answers.addFamilyMember(name: draftName, role: draftRole)
        draftName = ""
    }
}

private struct SettingCheckRow: View {
    var title: String
    var subtitle: String? = nil
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(KKFont.cta)
                            .foregroundStyle(KKColor.forest)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.forest)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Settings") {
    let defaults = UserDefaults(suiteName: "no.ketokasse.preview.settings")!
    defaults.removePersistentDomain(forName: "no.ketokasse.preview.settings")
    let answers = OnboardingState(defaults: defaults)
    answers.addFamilyMember(name: "Ola", role: .man)
    answers.goal = .everydayEnergy
    answers.selectNoAllergies()
    answers.housing = .apartment
    answers.floor = 3
    answers.plan = .standard
    return SettingsView(answers: answers, onRestart: {})
        .environment(HouseholdRepository.preview)
}
