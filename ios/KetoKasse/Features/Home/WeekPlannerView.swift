import SwiftUI

struct WeekPlannerView: View {
    @Environment(WeekStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ukeplan")
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .padding(.top, 8)
            Text("Hold de tre strekene og flytt middagen.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .padding(.top, 8)
            List {
                ForEach(PlanWeekday.allCases) { day in
                    WeekDayRow(
                        day: day,
                        dish: store.plan.dish(on: day),
                        reduceMotion: reduceMotion
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 8))
                    .listRowBackground(Color.clear)
                }
                .onMove(perform: moveRows)
                .deleteDisabled(true)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .environment(\.editMode, .constant(.active))
            .padding(.top, 16)
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
    }

    private func moveRows(from offsets: IndexSet, to destination: Int) {
        store.moveSlots(from: offsets, to: destination)
    }
}

private struct WeekDayRow: View {
    var day: PlanWeekday
    var dish: Dish?
    var reduceMotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(day.shortLabel)
                .font(KKFont.cta)
                .foregroundStyle(KKColor.forest)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(KKColor.mint)
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
                .fill(KKColor.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(KKColor.line, lineWidth: 1)
        )
        .accessibilityLabel("\(day.shortLabel), \(dish?.title ?? "Fri")")
    }
}

#Preview {
    WeekPlannerView()
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.week")!))
}
