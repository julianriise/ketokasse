import SwiftUI

struct JoinHouseholdView: View {
    @Environment(AuthService.self) private var auth
    @Environment(HouseholdRepository.self) private var household
    @Environment(WeekStore.self) private var weekStore
    @Environment(PointsStore.self) private var pointsStore

    @State private var isWorking = false
    @State private var didJoin = false
    @State private var shouldLeave = false
    @State private var bubble = "Du blir med i familien. Ukeplan og poeng synces."
    @State private var ctaTitle = "Bli med"

    var body: some View {
        CoachScreen(
            bubbleText: bubble,
            pose: didJoin ? .celebrate : .coach,
            ctaTitle: ctaTitle,
            ctaEnabled: !isWorking,
            caption: "Partneren logger inn med sin egen e-post.",
            secondaryTitle: (didJoin || shouldLeave) ? nil : "Avbryt",
            action: join,
            secondaryAction: (didJoin || shouldLeave) ? nil : cancel
        ) {
            VStack(alignment: .leading, spacing: 10) {
                bullet("Samme ukeplan på begge telefoner")
                bullet("Poeng dere deler")
                bullet("Hvem som kokte synes hos begge")
            }
            .padding(.top, 8)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(KKColor.forest)
                .accessibilityHidden(true)
            Text(text)
                .font(KKFont.body)
                .foregroundStyle(KKColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func join() {
        if didJoin || shouldLeave {
            auth.clearPendingInvite()
            return
        }
        guard let token = auth.pendingInviteToken, !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await household.redeem(token)
                await weekStore.syncRemote()
                await pointsStore.syncRemote()
                await household.startRealtime()
                didJoin = true
                bubble = "Dere er synket!"
                ctaTitle = "OK"
                try? await Task.sleep(for: .milliseconds(900))
                auth.clearPendingInvite()
            } catch let error as HouseholdError {
                applyFailure(error)
            } catch {
                applyFailure(HouseholdError.inviteInvalid)
            }
        }
    }

    private func applyFailure(_ error: HouseholdError) {
        switch error {
        case .offline:
            bubble = error.errorDescription ?? "Koble til nett og prøv igjen."
            ctaTitle = "Prøv igjen"
        default:
            bubble = error.errorDescription ?? "Invitasjonen er brukt eller utløpt. Be om en ny QR."
            ctaTitle = "OK"
            shouldLeave = true
        }
    }

    private func cancel() {
        auth.clearPendingInvite()
    }
}

#Preview("Bli med") {
    JoinHouseholdView()
        .environment(AuthService.previewSignedOut)
        .environment(HouseholdRepository.preview)
        .environment(WeekStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.join.week")!))
        .environment(PointsStore(defaults: UserDefaults(suiteName: "no.ketokasse.preview.join.points")!))
}
