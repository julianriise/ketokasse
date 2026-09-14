import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var answers = OnboardingState()
    @State private var weekStore = WeekStore()

    var body: some View {
        if onboardingComplete {
            HomeShellView(name: answers.primaryName, onRestart: restartOnboarding)
                .environment(weekStore)
        } else {
            OnboardingFlow(answers: answers) {
                onboardingComplete = true
            }
        }
    }

    private func restartOnboarding() {
        answers = OnboardingState()
        onboardingComplete = false
    }
}

#Preview("iPhone") {
    ContentView()
}
