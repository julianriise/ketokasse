import SwiftUI

struct GetStartedButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KKFont.cta)
                .tracking(KKFont.ctaTracking)
                .textCase(.uppercase)
                .foregroundStyle(KKColor.white)
                .frame(maxWidth: .infinity, minHeight: KKMotion.pillMinHeight)
        }
        .buttonStyle(DuoPillButtonStyle(reduceMotion: reduceMotion))
    }
}

private struct DuoPillButtonStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !reduceMotion
        let edge = pressed ? 0 : KKMotion.pillEdge
        configuration.label
            .background(KKColor.lime, in: .rect(cornerRadius: KKMotion.pillRadius))
            .padding(.bottom, edge)
            .background(KKColor.limeEdge, in: .rect(cornerRadius: KKMotion.pillRadius))
            .offset(y: pressed ? KKMotion.pillEdge : 0)
            .scaleEffect(pressed ? KKMotion.pressScale : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

#Preview {
    GetStartedButton(title: "KOM I GANG", action: {})
        .padding(24)
        .background(KKColor.mint)
}
