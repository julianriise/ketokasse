import SwiftUI

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

struct WelcomeView: View {
    var copy: WelcomeCopy = .bokmal

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hopToken = 0
    @State private var isBobbing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            mascot
            Text(copy.headline)
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            GetStartedButton(title: copy.cta, action: hop)
                .padding(.top, 32)
            Text(copy.footer)
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: hopToken)
        .onAppear { startBob() }
    }

    private var mascot: some View {
        ZStack {
            Circle()
                .fill(KKColor.sky)
                .frame(width: KKMotion.skyCircle, height: KKMotion.skyCircle)
            MascotView(hopToken: hopToken, isBobbing: isBobbing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("KetoKasse-maskot")
    }

    private func hop() {
        hopToken += 1
    }

    private func startBob() {
        guard !reduceMotion else { return }
        isBobbing = true
    }
}

#Preview("iPhone") {
    WelcomeView()
}
