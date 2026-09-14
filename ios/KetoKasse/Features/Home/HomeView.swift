import SwiftUI

struct HomeShellView: View {
    private enum Page: Hashable {
        case today
        case week
    }

    @Bindable var answers: OnboardingState
    var onRestart: () -> Void

    @State private var cookingDish: Dish?
    @State private var page: Page = .today
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $page) {
            NavigationStack {
                HomeView(answers: answers) {
                    showSettings = true
                } onStartDinner: { dish in
                    cookingDish = dish
                }
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
        .fullScreenCover(item: $cookingDish) { dish in
            CookingCover(dish: dish)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(answers: answers, onRestart: {
                showSettings = false
                onRestart()
            })
        }
    }
}

struct HomeView: View {
    @Bindable var answers: OnboardingState
    var onOpenSettings: () -> Void
    var onStartDinner: (Dish) -> Void

    @Environment(WeekStore.self) private var store
    @Environment(PointsStore.self) private var points
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var greeting: String {
        let trimmed = answers.primaryName
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
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text("\(points.total)")
                        .contentTransition(reduceMotion ? .identity : .numericText())
                }
                .font(KKFont.cta)
                .foregroundStyle(KKColor.forest)
                .accessibilityLabel("\(points.total) poeng")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.ink)
                }
                .accessibilityLabel("Innstillinger")
            }
        }
    }
}

private struct CookingCover: View {
    var dish: Dish

    var body: some View {
        if let recipe = RecipeRegistry.recipe(forDishTitle: dish.title) {
            CookingSessionView(recipe: recipe)
        } else {
            MissingRecipeView(title: dish.title)
        }
    }
}

private struct MissingRecipeView: View {
    var title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .multilineTextAlignment(.center)
            Text("Oppskrift mangler.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
            GetStartedButton(title: "Lukk", action: { dismiss() })
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
    }
}

#Preview("Home") {
    let defaults = UserDefaults(suiteName: "no.ketokasse.preview.home")!
    defaults.removePersistentDomain(forName: "no.ketokasse.preview.home")
    let answers = OnboardingState(defaults: defaults)
    answers.addFamilyMember(name: "Ola", role: .man)
    return HomeShellView(answers: answers, onRestart: {})
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.home.week")!))
        .environment(PointsStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.home.points")!))
}
