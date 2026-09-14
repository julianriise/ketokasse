import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var answers = OnboardingState()
    @State private var weekStore = WeekStore()
    @State private var pointsStore = PointsStore()

    var body: some View {
        if onboardingComplete {
            HomeShellView(answers: answers, onRestart: restartOnboarding)
                .environment(weekStore)
                .environment(pointsStore)
        } else {
            OnboardingFlow(answers: answers) {
                onboardingComplete = true
            }
        }
    }

    private func restartOnboarding() {
        answers.reset()
        onboardingComplete = false
    }
}

#Preview("iPhone") {
    ContentView()
}
