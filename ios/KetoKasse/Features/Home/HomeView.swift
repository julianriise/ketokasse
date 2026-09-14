import SwiftUI

struct HomeShellView: View {
    private enum Page: Hashable {
        case today
        case week
    }

    var name: String
    var onRestart: () -> Void

    @State private var cookingDish: Dish?
    @State private var page: Page = .today

    var body: some View {
        TabView(selection: $page) {
            HomeView(name: name, onRestart: onRestart) { dish in
                cookingDish = dish
            }
            .tag(Page.today)
            WeekPlannerView()
                .tag(Page.week)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .tint(KKColor.forest)
        .background(KKColor.white.ignoresSafeArea())
        .sensoryFeedback(.selection, trigger: page)
        .sheet(item: $cookingDish) { dish in
            CookingStubView(dish: dish)
        }
    }
}

struct HomeView: View {
    var name: String
    var onRestart: () -> Void
    var onStartDinner: (Dish) -> Void

    @Environment(WeekStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var greeting: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "I dag"
        }
        return "Hei, \(trimmed)"
    }

    var body: some View {
        let dish = store.todayDish
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Text(greeting)
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .multilineTextAlignment(.center)
            Text(dish?.title ?? "Fri kveld")
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(dish == nil ? KKColor.muted : KKColor.ink)
                .contentTransition(reduceMotion ? .identity : .opacity)
                .animation(KKMotion.snappy(reduceMotion), value: dish?.title)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            GetStartedButton(
                title: "Start middag",
                isEnabled: dish != nil,
                action: { if let dish { onStartDinner(dish) } }
            )
            .padding(.top, 32)
            Text("Sveip for ukeplanen")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .padding(.top, 16)
            Spacer(minLength: 24)
            Button("Start på nytt", action: onRestart)
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
    }
}

struct CookingStubView: View {
    var dish: Dish
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(dish.title)
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Oppskrift kommer.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
            GetStartedButton(title: "Lukk", action: { dismiss() })
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(KKColor.white.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Home") {
    HomeShellView(name: "Ola", onRestart: {})
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.home")!))
}
