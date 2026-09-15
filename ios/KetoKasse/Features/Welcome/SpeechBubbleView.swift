import SwiftUI

struct SpeechBubbleView: View {
    enum Tail {
        case leading
        case bottom
    }

    var text: String
    var tail: Tail

    private let radius: CGFloat = 16

    var body: some View {
        TypewriterText(text: text)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(KKColor.white, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(KKColor.line, lineWidth: 1.5)
            }
            .padding(.leading, tail == .leading ? 10 : 0)
            .padding(.bottom, tail == .bottom ? 10 : 0)
            .overlay(alignment: tail == .leading ? .leading : .bottom) {
                SpeechBubbleTail(tail: tail)
            }
    }
}

struct TypewriterText: View {
    var text: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleWords = 1

    private var words: [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    private var displayed: String {
        if reduceMotion { return text }
        return words.prefix(visibleWords).joined(separator: " ")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .font(KKFont.bubble)
                .hidden()
                .accessibilityHidden(true)
            Text(displayed)
                .font(KKFont.bubble)
                .foregroundStyle(KKColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .task(id: text) {
            await reveal()
        }
    }

    private func reveal() async {
        let parts = words
        if reduceMotion || parts.isEmpty {
            visibleWords = parts.count
            return
        }
        visibleWords = 1
        guard parts.count > 1 else { return }
        do {
            for count in 2...parts.count {
                try await Task.sleep(for: .milliseconds(80))
                visibleWords = count
            }
        } catch {
            return
        }
    }
}

private struct SpeechBubbleTail: View {
    var tail: SpeechBubbleView.Tail

    var body: some View {
        Canvas { context, size in
            var fill = Path()
            var stroke = Path()
            switch tail {
            case .leading:
                fill.move(to: CGPoint(x: size.width, y: 0))
                fill.addLine(to: CGPoint(x: 0, y: size.height / 2))
                fill.addLine(to: CGPoint(x: size.width, y: size.height))
                fill.closeSubpath()
                stroke.move(to: CGPoint(x: size.width, y: 1))
                stroke.addLine(to: CGPoint(x: 1, y: size.height / 2))
                stroke.addLine(to: CGPoint(x: size.width, y: size.height - 1))
            case .bottom:
                fill.move(to: CGPoint(x: 0, y: 0))
                fill.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                fill.addLine(to: CGPoint(x: size.width, y: 0))
                fill.closeSubpath()
                stroke.move(to: CGPoint(x: 1, y: 0))
                stroke.addLine(to: CGPoint(x: size.width / 2, y: size.height - 1))
                stroke.addLine(to: CGPoint(x: size.width - 1, y: 0))
            }
            context.fill(fill, with: .color(KKColor.white))
            context.stroke(
                stroke,
                with: .color(KKColor.line),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(
            width: tail == .leading ? 12 : 18,
            height: tail == .leading ? 18 : 12
        )
        .offset(
            x: tail == .leading ? 2 : 0,
            y: tail == .bottom ? -2 : 0
        )
        .accessibilityHidden(true)
    }
}

#Preview("Coach") {
    SpeechBubbleView(text: "Hva er viktigst?", tail: .leading)
        .padding(24)
        .background(KKColor.white)
}

#Preview("Hero") {
    SpeechBubbleView(text: "Den gøyeste måten å spise keto på", tail: .bottom)
        .padding(24)
        .background(KKColor.white)
}
