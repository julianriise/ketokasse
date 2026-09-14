import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var answers = OnboardingState()

    var body: some View {
        if onboardingComplete {
            HomePlaceholderView(name: answers.name)
        } else {
            OnboardingFlow(answers: answers) {
                onboardingComplete = true
            }
        }
    }
}

#Preview("iPhone") {
    ContentView()
}
