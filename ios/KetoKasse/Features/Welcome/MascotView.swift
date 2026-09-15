import SwiftUI

enum MascotPose {
    case hello
    case coach
    case celebrate
    case think

    var imageName: String {
        switch self {
        case .hello: "MascotHello"
        case .coach: "MascotCoach"
        case .celebrate: "MascotCelebrate"
        case .think: "MascotThink"
        }
    }
}

struct MascotView: View {
    var hopToken: Int
    var isBobbing: Bool
    var pose: MascotPose = .hello
    var size: CGFloat = KKMotion.mascotHero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hopFade: Double = 1

    var body: some View {
        Image(pose.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .opacity(hopFade)
            .modifier(MascotHopModifier(hopToken: hopToken, enabled: !reduceMotion))
            .offset(y: (!reduceMotion && isBobbing) ? KKMotion.bobY : 0)
            .animation(reduceMotion ? nil : KKMotion.bob, value: isBobbing)
            .onChange(of: hopToken) { _, _ in
                guard reduceMotion else { return }
                hopFade = 0.55
                withAnimation(.easeOut(duration: 0.25)) { hopFade = 1 }
            }
            .accessibilityHidden(true)
    }
}

private struct MascotHop: Equatable {
    var y: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

private struct MascotHopModifier: ViewModifier {
    var hopToken: Int
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.keyframeAnimator(
                initialValue: MascotHop(),
                trigger: hopToken
            ) { view, hop in
                view
                    .offset(y: hop.y)
                    .scaleEffect(x: hop.scaleX, y: hop.scaleY)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    SpringKeyframe(KKMotion.hopLift, duration: 0.22)
                    SpringKeyframe(0, duration: 0.32)
                }
                KeyframeTrack(\.scaleY) {
                    LinearKeyframe(0.92, duration: 0.1)
                    LinearKeyframe(1.08, duration: 0.16)
                    SpringKeyframe(1, duration: 0.28)
                }
                KeyframeTrack(\.scaleX) {
                    LinearKeyframe(1.06, duration: 0.1)
                    LinearKeyframe(0.94, duration: 0.16)
                    SpringKeyframe(1, duration: 0.28)
                }
            }
        } else {
            content
        }
    }
}

#Preview {
    MascotView(hopToken: 0, isBobbing: true)
        .background(KKColor.white)
}
