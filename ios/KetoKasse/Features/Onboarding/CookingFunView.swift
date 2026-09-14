import SwiftUI

struct CookingFunView: View {
    var onContinue: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var momentIndex = 0
    @State private var hopToken = 0
    @State private var isBobbing = false

    private let moments: [CookingMoment] = [
        CookingMoment(title: "Hakk grønnsakene", symbol: "carrot.fill"),
        CookingMoment(title: "Rør sausen", symbol: "fork.knife"),
        CookingMoment(title: "Stek kjøttet", symbol: "flame.fill"),
    ]

    var body: some View {
        OnboardingChrome(
            title: "Matlaging skal være gøy",
            support: "Maskoten følger deg gjennom middagen. Hakk, rør og stek.",
            ctaTitle: "FORTSETT",
            action: onContinue
        ) {
            mascot
                .padding(.top, 8)
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ForEach(moments) { moment in
                    momentRow(moment)
                }
            }
            .padding(.top, 8)

            Text("Dette gjør matlaging gøy.")
                .font(KKFont.body)
                .foregroundStyle(KKColor.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            Button("Neste steg", action: advanceMoment)
                .font(KKFont.cta)
                .tracking(KKFont.ctaTracking)
                .foregroundStyle(KKColor.forest)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
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
        .scaleEffect(160 / KKMotion.skyCircle)
        .frame(width: 160, height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("KetoKasse-maskot")
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

    private func advanceMoment() {
        setMoment((momentIndex + 1) % moments.count)
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

    private func startBob() {
        guard !reduceMotion else { return }
        isBobbing = true
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
