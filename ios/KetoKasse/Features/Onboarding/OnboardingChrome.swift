import SwiftUI

struct OnboardingChrome<Content: View>: View {
    var step: OnboardingStep
    var bubbleText: String
    var support: String? = nil
    var ctaTitle: String
    var ctaEnabled: Bool = true
    var action: () -> Void
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            topBar
            coach
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            OnboardingStickyFooter(
                title: ctaTitle,
                isEnabled: ctaEnabled,
                action: action
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(KKColor.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Tilbake")
            OnboardingProgressBar(progress: step.progress)
                .animation(reduceMotion ? nil : .snappy, value: step.progress)
        }
        .padding(.leading, 8)
        .padding(.trailing, 24)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .background(KKColor.white)
    }

    private var coach: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                OnboardingCoachMascot()
                SpeechBubbleView(text: bubbleText, tail: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let support {
                Text(support)
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 4)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct OnboardingStickyFooter: View {
    var title: String
    var isEnabled: Bool = true
    var caption: String? = nil
    var action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(KKColor.line)
                .frame(height: 1)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                GetStartedButton(title: title, isEnabled: isEnabled, action: action)
                if let caption {
                    Text(caption)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(KKColor.white)
    }
}

struct OnboardingProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(KKColor.line)
                Capsule()
                    .fill(KKColor.forest)
                    .frame(width: geo.size.width * clamped)
            }
        }
        .frame(height: 16)
        .accessibilityLabel("Fremgang")
        .accessibilityValue("\(Int((min(max(progress, 0), 1) * 100).rounded())) prosent")
    }
}

private struct OnboardingCoachMascot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBobbing = false

    var body: some View {
        MascotView(hopToken: 0, isBobbing: isBobbing, size: KKMotion.mascotCoach)
            .shadow(color: KKColor.ink.opacity(0.08), radius: 8, y: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("KetoKasse-maskot")
            .onAppear {
                guard !reduceMotion else { return }
                isBobbing = true
            }
    }
}

#Preview {
    NavigationStack {
        OnboardingChrome(
            step: .goal,
            bubbleText: "Hva er viktigst?",
            ctaTitle: "FORTSETT",
            action: {}
        ) {
            Text("Innhold")
                .font(KKFont.body)
        }
    }
}
