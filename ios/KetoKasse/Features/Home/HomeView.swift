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
        .sheet(item: $cookingDish) { dish in
            CookingStubView(dish: dish)
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
    let defaults = UserDefaults(suiteName: "no.ketokasse.preview.home")!
    defaults.removePersistentDomain(forName: "no.ketokasse.preview.home")
    let answers = OnboardingState(defaults: defaults)
    answers.addFamilyMember(name: "Ola", role: .man)
    return HomeShellView(answers: answers, onRestart: {})
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.home.week")!))
}
