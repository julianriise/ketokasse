import SwiftUI

struct CookingSessionView: View {
    let recipe: Recipe

    @Environment(PointsStore.self) private var points
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: CookingSession

    init(recipe: Recipe) {
        self.recipe = recipe
        _session = State(initialValue: CookingSession(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            phaseBody
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(KKColor.white, for: .navigationBar)
                .toolbar {
                    if session.phase != .score {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(KKFont.cta)
                                    .foregroundStyle(KKColor.ink)
                            }
                            .accessibilityLabel("Lukk")
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        PhaseDots(phase: session.phase)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(session.sessionPoints)")
                            .font(KKFont.cta)
                            .foregroundStyle(KKColor.forest)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                            .accessibilityLabel("\(session.sessionPoints) poeng")
                    }
                }
        }
        .tint(KKColor.forest)
        .background(KKColor.white.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: session.foundIDs.count)
        .sensoryFeedback(.success, trigger: session.phase)
        .animation(KKMotion.snappy(reduceMotion), value: session.phase)
        .animation(KKMotion.snappy(reduceMotion), value: session.stepIndex)
    }

    @ViewBuilder
    private var phaseBody: some View {
        switch session.phase {
        case .gather:
            GatherPhaseView(
                session: session,
                onAdvance: advance,
                onSkip: skipGather
            )
        case .prep, .cook, .serve:
            if let step = session.currentStep {
                TaskPhaseView(
                    step: step,
                    ctaTitle: taskCTA,
                    reduceMotion: reduceMotion,
                    onAdvance: advance
                )
            }
        case .score:
            ScorecardView(
                recipeTitle: recipe.dishTitle,
                session: session,
                onDone: { dismiss() }
            )
            .onAppear { session.commit(to: points) }
        }
    }

    private var taskCTA: String {
        if session.phase == .serve, session.stepIndex == recipe.serve.count - 1 {
            return "Se poeng"
        }
        return "Fortsett"
    }

    private func advance() {
        withAnimation(KKMotion.snappy(reduceMotion)) {
            session.advance()
        }
    }

    private func skipGather() {
        withAnimation(KKMotion.snappy(reduceMotion)) {
            session.skipRemainingGather()
        }
    }
}

private struct PhaseDots: View {
    var phase: RecipePhase

    var body: some View {
        HStack(spacing: 6) {
            ForEach(RecipePhase.allCases, id: \.self) { item in
                Circle()
                    .fill(item == phase ? KKColor.forest : KKColor.line)
                    .frame(width: item == phase ? 9 : 7, height: item == phase ? 9 : 7)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phase.title)
    }
}

private struct GatherPhaseView: View {
    @Bindable var session: CookingSession
    var onAdvance: () -> Void
    var onSkip: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Finn ingrediensene")
                        .font(KKFont.headline)
                        .tracking(KKFont.headlineTracking)
                        .foregroundStyle(KKColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(session.recipe.dishTitle)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 8) {
                        ForEach(session.recipe.gather) { step in
                            GatherRow(
                                step: step,
                                isFound: session.isFound(step.id),
                                action: {
                                    withAnimation(KKMotion.snappy(reduceMotion)) {
                                        session.toggleFound(step.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            safeButtons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
    }

    private var safeButtons: some View {
        VStack(spacing: 12) {
            GetStartedButton(
                title: "Fortsett",
                isEnabled: session.gatherComplete,
                action: onAdvance
            )
            if !session.gatherComplete {
                Button("Hopp over", action: onSkip)
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.muted)
                    .accessibilityHint("Gir færre poeng for ingredienser du ikke fant")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(KKColor.white)
    }
}

private struct GatherRow: View {
    var step: RecipeStep
    var isFound: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isFound ? "checkmark.circle.fill" : step.symbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isFound ? KKColor.lime : KKColor.forest)
                    .frame(width: 36, height: 36)
                    .contentTransition(.symbolEffect(.replace))
                Text(step.title)
                    .font(KKFont.body)
                    .foregroundStyle(isFound ? KKColor.lime : KKColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("+\(step.points)")
                    .font(KKFont.cta)
                    .foregroundStyle(isFound ? KKColor.lime : KKColor.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isFound ? KKColor.forest : KKColor.mint)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step.title)
        .accessibilityValue(isFound ? "Funnet" : "Ikke funnet")
        .accessibilityAddTraits(.isButton)
    }
}

private struct TaskPhaseView: View {
    var step: RecipeStep
    var ctaTitle: String
    var reduceMotion: Bool
    var onAdvance: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: step.symbolName)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(KKColor.forest)
                        .frame(width: 96, height: 96)
                        .background(KKColor.mint, in: Circle())
                        .symbolEffect(.bounce, value: reduceMotion ? "" : step.id)
                        .accessibilityHidden(true)
                    Text(step.title)
                        .font(KKFont.headline)
                        .tracking(KKFont.headlineTracking)
                        .foregroundStyle(KKColor.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(step.body)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            GetStartedButton(title: ctaTitle, action: onAdvance)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(KKColor.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
    }
}

private struct ScorecardView: View {
    var recipeTitle: String
    var session: CookingSession
    var onDone: () -> Void

    @Environment(PointsStore.self) private var points
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(KKColor.forest)
                        .frame(width: 88, height: 88)
                        .background(KKColor.lime, in: Circle())
                        .symbolEffect(.bounce, value: reduceMotion ? 0 : 1)
                        .accessibilityHidden(true)
                    Text("Bra jobba!")
                        .font(KKFont.headline)
                        .tracking(KKFont.headlineTracking)
                        .foregroundStyle(KKColor.ink)
                    Text(recipeTitle)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                        .multilineTextAlignment(.center)
                    Text("\(session.sessionPoints)")
                        .font(KKFont.headline)
                        .tracking(KKFont.headlineTracking)
                        .foregroundStyle(KKColor.forest)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .accessibilityLabel("\(session.sessionPoints) poeng denne gangen")
                    Text("poeng denne gangen")
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                    VStack(spacing: 8) {
                        scoreLine("Samle", session.points(in: .gather))
                        scoreLine("Forbered", session.points(in: .prep))
                        scoreLine("Stek", session.points(in: .cook))
                        scoreLine("Server", session.points(in: .serve))
                    }
                    .padding(.top, 8)
                    if session.skippedGather {
                        Text("Du hoppet over noen ingredienser, så samle-poengene ble lavere.")
                            .font(KKFont.body)
                            .foregroundStyle(KKColor.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                    Text("Totalt \(points.total) poeng")
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.forest)
                        .padding(.top, 8)
                        .accessibilityLabel("Totalt \(points.total) poeng")
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            GetStartedButton(title: "Ferdig", action: onDone)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .background(KKColor.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
    }

    private func scoreLine(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
                .font(KKFont.body)
                .foregroundStyle(KKColor.ink)
            Spacer()
            Text("\(value)")
                .font(KKFont.cta)
                .foregroundStyle(KKColor.forest)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(KKColor.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("Cooking") {
    let recipe = RecipeRegistry.recipe(forDishTitle: DishPool.pizzaTitle)!
    return CookingSessionView(recipe: recipe)
        .environment(PointsStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.cook")!))
}
