import SwiftUI
import UIKit

struct ShareHouseholdView: View {
    @Environment(HouseholdRepository.self) private var household

    @State private var isWorking = false
    @State private var copied = false
    @State private var bubble = "La partneren skanne — da får dere samme ukeplan."
    @State private var qrImage: UIImage?

    private var inviteURL: URL? {
        household.invite.map { InviteURL.webJoin($0.token) }
    }

    var body: some View {
        CoachScreen(
            bubbleText: bubble,
            pose: .coach,
            ctaTitle: "Lag ny kode",
            ctaEnabled: !isWorking,
            caption: "Partneren må ha appen og logge inn med sin e-post.",
            action: createInvite
        ) {
            VStack(spacing: 16) {
                qrBlock
                if let inviteURL {
                    truncatedLink(inviteURL)
                    Button("Kopier lenke", action: { copy(inviteURL) })
                        .font(KKFont.cta)
                        .foregroundStyle(KKColor.forest)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    Text(validityLabel)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .navigationTitle("Del husholdningen")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if household.invite == nil {
                await loadInvite(createNew: false)
            } else {
                refreshQR()
            }
        }
        .onChange(of: household.invite?.token) { _, _ in
            refreshQR()
        }
        .sensoryFeedback(.success, trigger: copied)
    }

    @ViewBuilder
    private var qrBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(KKColor.mint)
                .frame(maxWidth: 280)
                .aspectRatio(1, contentMode: .fit)
            if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .accessibilityLabel("QR-kode for å bli med i husholdningen")
            } else {
                ProgressView()
                    .tint(KKColor.forest)
                    .accessibilityLabel("Lager QR-kode")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func truncatedLink(_ url: URL) -> some View {
        Text(displayLink(url))
            .font(KKFont.body)
            .foregroundStyle(KKColor.muted)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Lenke")
            .accessibilityValue(url.absoluteString)
    }

    private var validityLabel: String {
        guard let expires = household.invite?.expiresAt else { return "Gyldig i 7 dager" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
        if days <= 0 { return "Utløper i dag" }
        if days == 1 { return "Gyldig i 1 dag" }
        return "Gyldig i \(days) dager"
    }

    private func displayLink(_ url: URL) -> String {
        let text = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        if text.count <= 36 { return text }
        return String(text.prefix(18)) + "…" + String(text.suffix(14))
    }

    private func createInvite() {
        Task { await loadInvite(createNew: true) }
    }

    private func loadInvite(createNew: Bool) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            if createNew {
                _ = try await household.createInvite()
            } else {
                _ = try await household.shareInvite()
            }
            bubble = "La partneren skanne — da får dere samme ukeplan."
            refreshQR()
        } catch {
            bubble = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
        }
    }

    private func refreshQR() {
        guard let inviteURL else {
            qrImage = nil
            return
        }
        qrImage = QRCodeImage.make(inviteURL.absoluteString)
    }

    private func copy(_ url: URL) {
        UIPasteboard.general.string = url.absoluteString
        copied = true
        bubble = "Lenken er kopiert."
    }
}

#Preview("Del") {
    NavigationStack {
        ShareHouseholdView()
            .environment(HouseholdRepository.preview)
    }
}
