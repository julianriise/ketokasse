import SwiftUI

struct WeekPlannerView: View {
    @Environment(WeekStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropTarget: PlanWeekday?
    @State private var swapCount = 0
    @State private var pressCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ukeplan")
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .padding(.top, 8)
            Text("Dra en middag til en annen dag for å bytte.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .padding(.top, 8)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(PlanWeekday.allCases) { day in
                        WeekDayRow(
                            day: day,
                            dish: store.plan.dish(on: day),
                            targeted: dropTarget == day,
                            reduceMotion: reduceMotion,
                            onPress: { pressCount += 1 },
                            onDrop: { title in acceptDrop(title, on: day) },
                            onTargeted: { hovering in
                                dropTarget = hovering ? day : nil
                            }
                        )
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            GetStartedButton(title: "Simuler ny uke", action: {
                withAnimation(KKMotion.snappy(reduceMotion)) {
                    store.simulateNewWeek()
                }
            })
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .animation(KKMotion.snappy(reduceMotion), value: dropTarget)
        .sensoryFeedback(.selection, trigger: dropTarget) { _, new in new != nil }
        .sensoryFeedback(.impact(weight: .medium), trigger: swapCount)
        .sensoryFeedback(.impact(weight: .light), trigger: pressCount)
    }

    private func acceptDrop(_ title: String, on day: PlanWeekday) -> Bool {
        dropTarget = nil
        guard !title.isEmpty,
              let from = store.plan.slots.firstIndex(where: { $0 == title }) else {
            return false
        }
        let to = day.rawValue - 1
        guard from != to else { return false }
        withAnimation(KKMotion.snappy(reduceMotion)) {
            store.moveDish(from: from, to: to)
        }
        swapCount += 1
        return true
    }
}

private struct WeekDayRow: View {
    var day: PlanWeekday
    var dish: Dish?
    var targeted: Bool
    var reduceMotion: Bool
    var onPress: () -> Void
    var onDrop: (String) -> Bool
    var onTargeted: (Bool) -> Void

    var body: some View {
        Button(action: onPress) {
            chrome
        }
        .buttonStyle(WeekDayRowButtonStyle(reduceMotion: reduceMotion))
        .draggableIfPresent(dish?.title) {
            chrome
                .scaleEffect(reduceMotion ? 1 : KKMotion.dragLiftScale)
                .shadow(color: KKColor.ink.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .dropDestination(for: String.self) { titles, _ in
            guard let title = titles.first else { return false }
            return onDrop(title)
        } isTargeted: { hovering in
            onTargeted(hovering)
        }
        .accessibilityLabel("\(day.shortLabel), \(dish?.title ?? "Fri")")
        .accessibilityHint(dish == nil ? "Slipp en middag her" : "Dra for å flytte")
    }

    private var chrome: some View {
        HStack(spacing: 12) {
            Text(day.shortLabel)
                .font(KKFont.cta)
                .foregroundStyle(targeted ? KKColor.lime : KKColor.forest)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(targeted ? KKColor.forest : KKColor.mint)
                )
            Text(dish?.title ?? "Fri")
                .font(KKFont.body)
                .foregroundStyle(dish == nil ? KKColor.muted : KKColor.ink)
                .contentTransition(reduceMotion ? .identity : .opacity)
                .animation(KKMotion.snappy(reduceMotion), value: dish?.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(targeted ? KKColor.mint : KKColor.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(targeted ? KKColor.forest : KKColor.line, lineWidth: targeted ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WeekDayRowButtonStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !reduceMotion
        configuration.label
            .scaleEffect(pressed ? KKMotion.pressScale : 1)
            .animation(KKMotion.press(reduceMotion), value: configuration.isPressed)
    }
}

private extension View {
    @ViewBuilder
    func draggableIfPresent<Preview: View>(
        _ title: String?,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        if let title {
            draggable(title, preview: preview)
        } else {
            self
        }
    }
}

#Preview {
    WeekPlannerView()
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.week")!))
}
