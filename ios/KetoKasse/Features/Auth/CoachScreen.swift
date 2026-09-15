import SwiftUI

struct CoachScreen<Content: View>: View {
    var bubbleText: String
    var pose: MascotPose = .coach
    var ctaTitle: String
    var ctaEnabled: Bool = true
    var caption: String? = nil
    var secondaryTitle: String? = nil
    var action: () -> Void
    var secondaryAction: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBobbing = false

    var body: some View {
        VStack(spacing: 0) {
            coach
                .padding(.horizontal, 24)
                .padding(.top, 16)
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
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
    }

    private var coach: some View {
        HStack(alignment: .center, spacing: 8) {
            MascotView(hopToken: 0, isBobbing: isBobbing, pose: pose, size: KKMotion.mascotCoach)
                .shadow(color: KKColor.ink.opacity(0.08), radius: 8, y: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("KetoKasse-maskot")
                .onAppear {
                    guard !reduceMotion else { return }
                    isBobbing = true
                }
            SpeechBubbleView(text: bubbleText, tail: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(KKColor.line)
                .frame(height: 1)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                GetStartedButton(title: ctaTitle, isEnabled: ctaEnabled, action: action)
                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                }
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
