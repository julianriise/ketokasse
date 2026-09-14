import SwiftUI

struct HomePlaceholderView: View {
    var name: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBobbing = false

    private var greeting: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Hei"
        }
        return "Hei, \(trimmed)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            mascot
            Text(greeting)
                .font(KKFont.headline)
                .tracking(KKFont.headlineTracking)
                .foregroundStyle(KKColor.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            Text("Uka di er klar.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .onAppear { startBob() }
    }

    private var mascot: some View {
        ZStack {
            Circle()
                .fill(KKColor.sky)
                .frame(width: KKMotion.skyCircle, height: KKMotion.skyCircle)
            MascotView(hopToken: 0, isBobbing: isBobbing)
        }
        .scaleEffect(160 / KKMotion.skyCircle)
        .frame(width: 160, height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("KetoKasse-maskot")
    }

    private func startBob() {
        guard !reduceMotion else { return }
        isBobbing = true
    }
}

#Preview {
    HomePlaceholderView(name: "Ola")
}
