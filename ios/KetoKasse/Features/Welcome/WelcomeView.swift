import SwiftUI

struct WelcomeView: View {
    var copy: WelcomeCopy = .bokmal
    var onContinue: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hopToken = 0
    @State private var isBobbing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)
            VStack(spacing: 8) {
                SpeechBubbleView(text: copy.headline, tail: .bottom)
                    .padding(.horizontal, 32)
                MascotView(hopToken: hopToken, isBobbing: isBobbing, size: KKMotion.mascotHero)
                    .shadow(color: KKColor.ink.opacity(0.10), radius: 18, y: 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("KetoKasse-maskot")
            }
            Spacer(minLength: 16)
            OnboardingStickyFooter(
                title: copy.cta,
                caption: copy.footer,
                action: hop
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: hopToken)
        .onAppear { startBob() }
    }

    private func hop() {
        hopToken += 1
        onContinue()
    }

    private func startBob() {
        guard !reduceMotion else { return }
        isBobbing = true
    }
}

struct WelcomeCopy: Equatable, Sendable {
    var headline: String
    var cta: String
    var footer: String

    static let bokmal = WelcomeCopy(
        headline: "Den gøyeste måten å spise keto på",
        cta: "KOM I GANG",
        footer: "Ingen binding · Avslutt når som helst"
    )
}

#Preview("iPhone") {
    WelcomeView()
}
