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

    private var canSend: Bool {
        AuthService.isValidEmail(trimmedEmail) && !isSending && (step == .email || cooldown == 0)
    }

    private var householdReady: Bool {
        household.householdID != nil && household.lastError == nil
    }

    private var bubbleText: String {
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
            if household.lastError != nil {
                return household.lastError ?? "Koble til nett og prøv igjen."
            }
            if !householdReady {
                return "Setter opp familien…"
            }
            return "Du er inne! La oss komme i gang."
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
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KKColor.white.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: hopToken)
        .onAppear {
            if !reduceMotion { isBobbing = true }
            syncStepWithAuth()
        }
        .onChange(of: auth.phase) { _, _ in syncStepWithAuth() }
        .onChange(of: auth.needsHandoff) { _, _ in syncStepWithAuth() }
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

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(KKColor.line)
                .frame(height: 1)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                GetStartedButton(
                    title: primaryTitle,
                    isEnabled: primaryEnabled,
                    action: primaryAction
                )
                if step == .inbox {
                    Button("Bytt e-post", action: changeEmail)
                        .font(KKFont.body)
                        .foregroundStyle(KKColor.muted)
                }
                Text(footerCaption)
                    .font(KKFont.body)
                    .foregroundStyle(KKColor.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(KKColor.white)
    }

    private var mascotPose: MascotPose {
        switch step {
        case .email: .hello
        case .inbox: .think
        case .ready: householdReady ? .celebrate : .coach
        }
    }

    private var primaryTitle: String {
        switch step {
        case .email: "Send lenke"
        case .inbox: "Send på nytt"
        case .ready: household.lastError != nil ? "Prøv igjen" : "Fortsett"
        }
    }

    private var primaryEnabled: Bool {
        switch step {
        case .email, .inbox: canSend
        case .ready: householdReady || household.lastError != nil
        }
    }

    private var footerCaption: String {
        if step == .ready {
            return householdReady
                ? "Ingen passord. Du er logget inn på denne telefonen."
                : "Vi gjør klar husholdningen."
        }
        if step == .inbox, cooldown > 0 {
            return "Ny lenke om \(cooldown) s"
        }
        return "Ingen passord. Åpne lenken på denne telefonen."
    }

    private func primaryAction() {
        switch step {
        case .email, .inbox:
            sendLink()
        case .ready:
            if household.lastError != nil {
                Task { await household.ensure() }
            } else {
                auth.acceptHandoff()
            }
        }
    }

    private func syncStepWithAuth() {
        guard auth.phase == .signedIn, auth.needsHandoff else { return }
        if step != .ready {
            hopToken += 1
        }
        bubbleOverride = nil
        emailFocused = false
        step = .ready
    }

    private func sendLink() {
        let value = trimmedEmail
        guard AuthService.isValidEmail(value) else {
            fieldError = "Skriv inn en gyldig e-post."
            emailFocused = true
            return
        }
        guard !isSending else { return }
        if step == .inbox, cooldown > 0 { return }
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
                    bubbleOverride = "Vent litt og prøv igjen."
                } else if mapped == .invalidEmail {
                    fieldError = mapped.errorDescription
                } else {
                    bubbleOverride = mapped.errorDescription
                }
            }
        }
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
