import SwiftUI

struct WeekPlannerView: View {
    @Environment(WeekStore.self) private var store
    @State private var dropTarget: PlanWeekday?

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
                        dayRow(day)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            GetStartedButton(title: "Simuler ny uke", action: {
                store.simulateNewWeek()
            })
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .animation(.snappy, value: store.plan)
        .animation(.snappy, value: dropTarget)
    }

    private func dayRow(_ day: PlanWeekday) -> some View {
        let dish = store.plan.dish(on: day)
        let targeted = dropTarget == day
        return HStack(spacing: 12) {
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
        .draggableIfPresent(dish?.title)
        .dropDestination(for: String.self) { titles, _ in
            dropTarget = nil
            guard let title = titles.first, !title.isEmpty else { return false }
            guard let from = store.plan.slots.firstIndex(where: { $0 == title }) else { return false }
            store.moveDish(from: from, to: day.rawValue - 1)
            return true
        } isTargeted: { hovering in
            dropTarget = hovering ? day : nil
        }
        .accessibilityLabel("\(day.shortLabel), \(dish?.title ?? "Fri")")
        .accessibilityHint(dish == nil ? "Slipp en middag her" : "Dra for å flytte")
    }
}

private extension View {
    @ViewBuilder
    func draggableIfPresent(_ title: String?) -> some View {
        if let title {
            draggable(title)
        } else {
            self
        }
    }
}

#Preview {
    WeekPlannerView()
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.week")!))
}
