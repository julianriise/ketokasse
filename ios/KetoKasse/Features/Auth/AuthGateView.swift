import SwiftUI

struct AuthGateView: View {
    private enum Step {
        case email
        case inbox
        case ready
    }

    @Environment(AuthService.self) private var auth
    @Environment(HouseholdRepository.self) private var household
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @State private var step: Step = .email
    @State private var email = ""
    @State private var fieldError: String?
    @State private var bubbleOverride: String?
    @State private var isSending = false
    @State private var cooldown = 0
    @State private var hopToken = 0
    @State private var isBobbing = false
    @FocusState private var emailFocused: Bool

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func canSend(lockRemaining: TimeInterval) -> Bool {
        lockRemaining <= 0
            && cooldown == 0
            && !isSending
            && AuthService.isValidEmail(trimmedEmail)
    }

    private var bubbleText: String {
        if auth.emailLockRemaining() > 0 {
            return AuthFlowError.rateLimited.errorDescription ?? bubbleOverride ?? ""
        }
        if let bubbleOverride { return bubbleOverride }
        if auth.linkError == .expiredLink {
            return "Lenken er utløpt."
        }
        switch step {
        case .email:
            return "Hei! Logg inn med e-post — vi sender en magisk lenke."
        case .inbox:
            return "Vi sendte en lenke til \(trimmedEmail). Trykk den for å fortsette."
        case .ready:
            return household.lastError ?? "Koble til nett og prøv igjen."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 24)
                    SpeechBubbleView(text: bubbleText, tail: .bottom)
                        .padding(.horizontal, 32)
                    MascotView(
                        hopToken: hopToken,
                        isBobbing: isBobbing,
                        pose: mascotPose,
                        size: KKMotion.mascotHero
                    )
                    .shadow(color: KKColor.ink.opacity(0.10), radius: 18, y: 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("KetoKasse-maskot")
                    if step == .email {
                        emailField
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    } else if step == .inbox {
                        inboxGlyph
                            .padding(.top, 8)
                    }
                    Spacer(minLength: 16)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let lockRemaining = auth.emailLockRemaining(at: context.date)
                footer(lockRemaining: lockRemaining, now: context.date)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: hopToken)
        .onAppear {
            if !reduceMotion { isBobbing = true }
            auth.refreshEmailLock()
            applyStoredRateLimit()
            syncStepWithAuth()
        }
        .onChange(of: auth.phase) { _, _ in syncStepWithAuth() }
        .onChange(of: auth.needsHandoff) { _, _ in syncStepWithAuth() }
        .onChange(of: household.lastError) { _, _ in syncStepWithAuth() }
        .onChange(of: auth.linkError) { _, error in
            if error == .expiredLink {
                bubbleOverride = "Lenken er utløpt."
                step = .email
            }
        }
        .task(id: cooldown) {
            guard cooldown > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            if cooldown > 0 { cooldown -= 1 }
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            field
            if let fieldError {
                Text(fieldError)
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.berry)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(fieldError)
            }
        }
    }

    @ViewBuilder
    private var field: some View {
        if #available(iOS 18.0, *) {
            emailTextField.writingToolsBehavior(.disabled)
        } else {
            emailTextField
        }
    }

    private var emailTextField: some View {
        TextField("E-post", text: $email)
            .font(KKFont.body)
            .foregroundStyle(KKColor.ink)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.send)
            .focused($emailFocused)
            .onSubmit(sendLink)
            .padding(16)
            .background(KKColor.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(KKColor.line, lineWidth: 1)
            )
    }

    private var inboxGlyph: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.open.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(KKColor.forest)
                .frame(width: 88, height: 88)
                .background(KKColor.mint, in: Circle())
                .accessibilityHidden(true)
            Button("Åpne Mail") {
                if let url = URL(string: "message://") {
                    openURL(url)
                }
            }
            .font(KKFont.body)
            .foregroundStyle(KKColor.forest)
        }
    }

    private func footer(lockRemaining: TimeInterval, now: Date) -> some View {
        let locked = lockRemaining > 0
        return VStack(spacing: 0) {
            Rectangle()
                .fill(KKColor.line)
                .frame(height: 1)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                GetStartedButton(
                    title: primaryTitle(lockRemaining: lockRemaining),
                    isEnabled: primaryEnabled(lockRemaining: lockRemaining),
                    action: primaryAction
                )
                .accessibilityValue(locked ? lockTitle(lockRemaining) : "")
                if step == .inbox {
                    Button("Bytt e-post", action: changeEmail)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                }
                if step == .ready, household.lastError != nil {
                    Button("Logg ut") {
                        household.reset()
                        Task { await auth.signOut() }
                    }
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.muted)
                }
                Text(footerCaption(lockRemaining: lockRemaining))
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.muted)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(KKColor.white)
        .onChange(of: locked) { _, isLocked in
            if !isLocked {
                auth.clearEmailRateLimitIfExpired(at: now)
                if bubbleOverride == AuthFlowError.rateLimited.errorDescription {
                    bubbleOverride = nil
                }
            }
        }
    }

    private var mascotPose: MascotPose {
        switch step {
        case .email: .hello
        case .inbox: .think
        case .ready: .think
        }
    }

    private func primaryTitle(lockRemaining: TimeInterval) -> String {
        if lockRemaining > 0 {
            return lockTitle(lockRemaining)
        }
        switch step {
        case .email: return "Send lenke"
        case .inbox: return "Send på nytt"
        case .ready: return "Prøv igjen"
        }
    }

    private func primaryEnabled(lockRemaining: TimeInterval) -> Bool {
        switch step {
        case .email, .inbox: canSend(lockRemaining: lockRemaining)
        case .ready: household.lastError != nil
        }
    }

    private func footerCaption(lockRemaining: TimeInterval) -> String {
        if step == .ready {
            return "Vi gjør klar husholdningen."
        }
        if lockRemaining > 0 {
            return "Maks to e-poster i timen. Knappen åpner når tiden er ute."
        }
        if cooldown > 0 {
            return cooldownLabel
        }
        return "Ingen passord. Åpne lenken på denne telefonen."
    }

    private func lockTitle(_ remaining: TimeInterval) -> String {
        let total = max(0, Int(remaining.rounded(.up)))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "Vent %d:%02d", minutes, seconds)
    }

    private func primaryAction() {
        switch step {
        case .email, .inbox:
            sendLink()
        case .ready:
            Task { await household.ensure() }
        }
    }

    private func syncStepWithAuth() {
        guard auth.phase == .signedIn, auth.needsHandoff, household.lastError != nil else { return }
        bubbleOverride = nil
        emailFocused = false
        step = .ready
    }

    private func sendLink() {
        if auth.emailLockRemaining() > 0 { return }
        let value = trimmedEmail
        guard AuthService.isValidEmail(value) else {
            fieldError = "Skriv inn en gyldig e-post."
            emailFocused = true
            return
        }
        guard !isSending else { return }
        if cooldown > 0 { return }
        fieldError = nil
        bubbleOverride = nil
        hopToken += 1
        isSending = true
        Task {
            defer { isSending = false }
            do {
                try await auth.sendMagicLink(email: value)
                step = .inbox
                cooldown = 45
                emailFocused = false
            } catch {
                let mapped = AuthService.mapSendError(error)
                if mapped == .rateLimited {
                    bubbleOverride = mapped.errorDescription
                } else if mapped == .invalidEmail {
                    fieldError = mapped.errorDescription
                } else {
                    bubbleOverride = mapped.errorDescription
                }
            }
        }
    }

    private var cooldownLabel: String {
        if cooldown >= 60 {
            let minutes = Int((Double(cooldown) / 60.0).rounded(.up))
            if minutes == 1 { return "Ny lenke om 1 minutt" }
            return "Ny lenke om \(minutes) minutter"
        }
        return "Ny lenke om \(cooldown) s"
    }

    private func applyStoredRateLimit() {
        guard auth.emailLockRemaining() > 0 else { return }
        bubbleOverride = AuthFlowError.rateLimited.errorDescription
    }

    private func changeEmail() {
        step = .email
        bubbleOverride = nil
        auth.linkError = nil
        emailFocused = true
    }
}

#Preview("Velkommen") {
    AuthGateView()
        .environment(AuthService.previewSignedOut)
        .environment(HouseholdRepository())
}

#Preview("Sjekk e-post") {
    AuthGateView()
        .environment(AuthService.previewSignedOut)
        .environment(HouseholdRepository())
}
