import SwiftUI

struct MascotView: View {
    var hopToken: Int
    var isBobbing: Bool
    var size: CGFloat = KKMotion.mascotHero

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hopFade: Double = 1

    var body: some View {
        drawing
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

    private var drawing: some View {
        MascotDrawing()
            .frame(width: 80, height: 80)
            .scaleEffect(size / 80)
            .frame(width: size, height: size)
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

/// Placeholder crate on an 80pt artboard. Replace this view with an Illustrator
/// image in Assets.xcassets. Callers pass `size` so Duo layout stays put.
private struct MascotDrawing: View {
    var body: some View {
        ZStack {
            SproutLeaf()
            CrateBody()
            CrateFace()
        }
    }
}

private struct SproutLeaf: View {
    var body: some View {
        ZStack {
            SproutOutline()
                .fill(KKColor.forest)
            SproutVein()
                .stroke(KKColor.forest, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

private struct SproutOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 80
        var path = Path()
        path.move(to: CGPoint(x: 58 * s, y: 8 * s))
        path.addCurve(
            to: CGPoint(x: 64 * s, y: 30 * s),
            control1: CGPoint(x: 68 * s, y: 11 * s),
            control2: CGPoint(x: 72 * s, y: 22 * s)
        )
        path.addCurve(
            to: CGPoint(x: 58 * s, y: 8 * s),
            control1: CGPoint(x: 54 * s, y: 27 * s),
            control2: CGPoint(x: 50 * s, y: 16 * s)
        )
        return path
    }
}

private struct SproutVein: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 80
        var path = Path()
        path.move(to: CGPoint(x: 62 * s, y: 14 * s))
        path.addCurve(
            to: CGPoint(x: 66.6 * s, y: 24 * s),
            control1: CGPoint(x: 63.6 * s, y: 17.4 * s),
            control2: CGPoint(x: 65.2 * s, y: 20.6 * s)
        )
        return path
    }
}

private struct CrateBody: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .circular)
                .fill(KKColor.forest)
                .frame(width: 58, height: 48)
                .offset(x: 11, y: 22)
            RoundedRectangle(cornerRadius: 10, style: .circular)
                .fill(KKColor.limeLid)
                .frame(width: 58, height: 16)
                .offset(x: 11, y: 22)
            RoundedRectangle(cornerRadius: 5, style: .circular)
                .fill(KKColor.limeSprout)
                .frame(width: 44, height: 10)
                .offset(x: 18, y: 18)
            RoundedRectangle(cornerRadius: 2.5, style: .circular)
                .fill(KKColor.limeEdge.opacity(0.4))
                .frame(width: 5, height: 24)
                .offset(x: 25, y: 40)
            RoundedRectangle(cornerRadius: 2.5, style: .circular)
                .fill(KKColor.limeEdge.opacity(0.4))
                .frame(width: 5, height: 24)
                .offset(x: 50, y: 40)
        }
        .frame(width: 80, height: 80, alignment: .topLeading)
    }
}

private struct CrateFace: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Eye(x: 30, y: 46)
            Eye(x: 50, y: 46)
            Ellipse()
                .fill(KKColor.blush)
                .frame(width: 8.4, height: 5)
                .offset(x: 16.8, y: 51.5)
            Ellipse()
                .fill(KKColor.blush)
                .frame(width: 8.4, height: 5)
                .offset(x: 54.8, y: 51.5)
            Smile()
                .stroke(KKColor.forest, style: StrokeStyle(lineWidth: 3.1, lineCap: .round))
        }
        .frame(width: 80, height: 80, alignment: .topLeading)
    }
}

private struct Eye: View {
    var x: CGFloat
    var y: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(KKColor.white)
                .frame(width: 14.4, height: 14.4)
                .offset(x: x - 7.2, y: y - 7.2)
            Circle()
                .fill(KKColor.forest)
                .frame(width: 6.6, height: 6.6)
                .offset(x: x + 2 - 3.3, y: y + 1.4 - 3.3)
            Circle()
                .fill(KKColor.white)
                .frame(width: 2.3, height: 2.3)
                .offset(x: x + 3.4 - 1.15, y: y - 1.15)
        }
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 80
        var path = Path()
        path.move(to: CGPoint(x: 33 * s, y: 58 * s))
        path.addCurve(
            to: CGPoint(x: 47 * s, y: 58 * s),
            control1: CGPoint(x: 36.6 * s, y: 63.2 * s),
            control2: CGPoint(x: 43.4 * s, y: 63.2 * s)
        )
        return path
    }
}

#Preview {
    MascotView(hopToken: 0, isBobbing: true)
        .background(KKColor.white)
}
