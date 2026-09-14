import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var answers = OnboardingState()

    var body: some View {
        if onboardingComplete {
            HomePlaceholderView(name: answers.name, onRestart: restartOnboarding)
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
