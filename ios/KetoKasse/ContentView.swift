import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("onboardingUserID") private var onboardingUserID = ""
    @Environment(AuthService.self) private var auth
    @Environment(HouseholdRepository.self) private var household
    @State private var answers = OnboardingState()
    @State private var weekStore = WeekStore()
    @State private var pointsStore = PointsStore()
    @State private var showPreparing = false

    private var onboardingDoneForUser: Bool {
        guard let id = auth.userID?.uuidString else { return false }
        return onboardingComplete && onboardingUserID == id
    }

    var body: some View {
        Group {
            switch auth.phase {
            case .unknown:
                splash
            case .signedOut:
                AuthGateView()
            case .signedIn:
                if auth.needsHandoff {
                    AuthGateView()
                } else {
                    signedInRoot
                }
            }
        }
        .environment(weekStore)
        .environment(pointsStore)
        .task { auth.startListening() }
        .task(id: auth.userID) {
            await bootstrapHousehold()
        }
        .onChange(of: household.remoteWeekSlots) { _, slots in
            if let slots { weekStore.applyRemoteSlots(slots) }
        }
        .onChange(of: household.remotePoints) { _, value in
            if let value { pointsStore.applyRemote(value) }
        }
    }

    @ViewBuilder
    private var signedInRoot: some View {
        if household.householdID == nil {
            if household.lastError != nil {
                CoachScreen(
                    bubbleText: household.lastError ?? "Koble til nett og prøv igjen.",
                    pose: .think,
                    ctaTitle: "Prøv igjen",
                    action: { Task { await bootstrapHousehold() } }
                ) {
                    EmptyView()
                }
            } else if showPreparing {
                PreparingHouseholdView()
            } else {
                splash
            }
        } else if auth.pendingInviteToken != nil {
            JoinHouseholdView()
        } else if onboardingDoneForUser {
            HomeShellView(answers: answers, onRestart: restartOnboarding, onSignOut: signOut)
        } else {
            OnboardingFlow(answers: answers) {
                onboardingComplete = true
                onboardingUserID = auth.userID?.uuidString ?? ""
            }
        }
    }

    private var splash: some View {
        ZStack {
            KKColor.white.ignoresSafeArea()
            ProgressView()
                .tint(KKColor.forest)
                .accessibilityLabel("Laster")
        }
    }

    private func bootstrapHousehold() async {
        guard auth.phase == .signedIn else {
            showPreparing = false
            weekStore.remote = nil
            pointsStore.remote = nil
            household.reset()
            return
        }
        if household.householdID != nil {
            weekStore.remote = household
            pointsStore.remote = household
            await weekStore.syncRemote()
            await pointsStore.syncRemote()
            return
        }
        showPreparing = false
        let flash = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if household.householdID == nil {
                showPreparing = true
            }
        }
        await household.ensure()
        weekStore.remote = household
        pointsStore.remote = household
        await weekStore.syncRemote()
        await pointsStore.syncRemote()
        await household.startRealtime()
        flash.cancel()
        showPreparing = false
    }

    private func restartOnboarding() {
        answers.reset()
        onboardingComplete = false
        onboardingUserID = ""
    }

    private func signOut() {
        Task { await auth.signOut() }
    }
}

#Preview("iPhone") {
    ContentView()
        .environment(AuthService.previewSignedOut)
        .environment(HouseholdRepository())
}
