import SwiftUI

struct MealPlanWeekView: View {
    var onContinue: () -> Void = {}

    @State private var slots: [WeekMealSlot] = WeekMealSlot.sampleWeek
    @State private var selectedWeekday: DeliveryWeekday?

    var body: some View {
        OnboardingChrome(
            title: "Fem middager på sju dager",
            support: "To kvelder står tomme. Trykk på en middag, så en annen, for å bytte. Vi minner deg på å ta frossent kjøtt ut dagen før.",
            ctaTitle: "FORTSETT",
            action: onContinue
        ) {
            VStack(spacing: 8) {
                ForEach(slots) { slot in
                    slotButton(slot)
                }
            }
            .padding(.top, 8)
            .animation(.snappy, value: selectedWeekday)
            .animation(.snappy, value: slots)
        }
        .sensoryFeedback(.selection, trigger: selectedWeekday)
    }

    private func slotButton(_ slot: WeekMealSlot) -> some View {
        let isSelected = selectedWeekday == slot.weekday
        let isEmpty = slot.meal == nil
        return Button {
            tapSlot(slot.weekday)
        } label: {
            HStack(spacing: 12) {
                Text(slot.weekday.shortLabel)
                    .font(KKFont.cta)
                    .foregroundStyle(isSelected ? KKColor.lime : KKColor.forest)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? KKColor.forest : KKColor.mint)
                    )
                Text(slot.meal ?? "Fri")
                    .font(KKFont.body)
                    .foregroundStyle(isEmpty ? KKColor.muted : KKColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? KKColor.mint : KKColor.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? KKColor.forest : KKColor.line, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(slot.weekday.shortLabel), \(slot.meal ?? "Fri")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func tapSlot(_ weekday: DeliveryWeekday) {
        if let selectedWeekday {
            if selectedWeekday == weekday {
                self.selectedWeekday = nil
            } else {
                swapMeals(selectedWeekday, weekday)
                self.selectedWeekday = nil
            }
        } else {
            selectedWeekday = weekday
        }
    }

    private func swapMeals(_ a: DeliveryWeekday, _ b: DeliveryWeekday) {
        guard let i = slots.firstIndex(where: { $0.weekday == a }),
              let j = slots.firstIndex(where: { $0.weekday == b }) else { return }
        let mealA = slots[i].meal
        slots[i].meal = slots[j].meal
        slots[j].meal = mealA
    }
}

private struct WeekMealSlot: Identifiable, Equatable {
    var weekday: DeliveryWeekday
    var meal: String?

    var id: DeliveryWeekday { weekday }

    static let sampleWeek: [WeekMealSlot] = [
        WeekMealSlot(weekday: .monday, meal: "Laks og brokkoli"),
        WeekMealSlot(weekday: .tuesday, meal: "Kylling i ovn"),
        WeekMealSlot(weekday: .wednesday, meal: nil),
        WeekMealSlot(weekday: .thursday, meal: "Biff og asparges"),
        WeekMealSlot(weekday: .friday, meal: "Torsk med smør"),
        WeekMealSlot(weekday: .saturday, meal: nil),
        WeekMealSlot(weekday: .sunday, meal: "Egg og bacon"),
    ]
}

#Preview {
    NavigationStack {
        MealPlanWeekView()
    }
}
