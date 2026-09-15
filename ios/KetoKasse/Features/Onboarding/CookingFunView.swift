import SwiftUI

struct CookingFunView: View {
    var onContinue: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var momentIndex = 0
    @State private var hopToken = 0

    private let moments: [CookingMoment] = [
        CookingMoment(title: "Hakk grønnsakene", symbol: "carrot.fill"),
        CookingMoment(title: "Rør sausen", symbol: "fork.knife"),
        CookingMoment(title: "Stek kjøttet", symbol: "flame.fill"),
    ]

    var body: some View {
        OnboardingChrome(
            step: .cooking,
            bubbleText: "Matlaging skal være gøy",
            support: "Hakk, rør og stek.",
            ctaTitle: "FORTSETT",
            action: onContinue
        ) {
            VStack(spacing: 10) {
                ForEach(moments) { moment in
                    momentRow(moment)
                }
            }
            .padding(.top, 8)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hopToken)
    }

    private func momentRow(_ moment: CookingMoment) -> some View {
        let isActive = moments[momentIndex].id == moment.id
        return Button {
            selectMoment(moment)
        } label: {
            HStack(spacing: 14) {
                momentSymbol(moment.symbol, isActive: isActive)
                    .frame(width: 36, height: 36)
                Text(moment.title)
                    .font(KKFont.body)
                    .foregroundStyle(isActive ? KKColor.lime : KKColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isActive ? KKColor.forest : KKColor.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(moment.title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    @ViewBuilder
    private func momentSymbol(_ name: String, isActive: Bool) -> some View {
        let image = Image(systemName: name)
            .font(.title2)
            .foregroundStyle(isActive ? KKColor.lime : KKColor.forest)
            .symbolRenderingMode(.monochrome)
        if reduceMotion {
            image
        } else {
            image.symbolEffect(.bounce, value: hopToken)
        }
    }

    private func selectMoment(_ moment: CookingMoment) {
        guard let index = moments.firstIndex(where: { $0.id == moment.id }) else { return }
        setMoment(index)
    }

    private func setMoment(_ index: Int) {
        hopToken += 1
        if reduceMotion {
            momentIndex = index
        } else {
            withAnimation(.snappy) {
                momentIndex = index
            }
        }
    }
}

private struct CookingMoment: Identifiable, Equatable {
    var title: String
    var symbol: String
    var id: String { symbol }
}

#Preview {
    NavigationStack {
        CookingFunView()
    }
}
