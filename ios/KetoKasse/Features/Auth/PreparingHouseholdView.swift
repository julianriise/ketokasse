import SwiftUI

struct PreparingHouseholdView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBobbing = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            HStack(alignment: .center, spacing: 8) {
                MascotView(hopToken: 0, isBobbing: isBobbing, pose: .coach, size: KKMotion.mascotCoach)
                    .shadow(color: KKColor.ink.opacity(0.08), radius: 8, y: 4)
                    .accessibilityHidden(true)
                SpeechBubbleView(text: "Setter opp familien…", tail: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .onAppear {
            guard !reduceMotion else { return }
            isBobbing = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Setter opp familien")
    }
}

#Preview {
    PreparingHouseholdView()
}
