import Foundation
import Observation
import Supabase

enum AuthPhase: Equatable {
    case unknown
    case signedOut
    case signedIn
}

enum AuthFlowError: Equatable {
    case invalidEmail
    case rateLimited
    case expiredLink
    case missingConfig
    case message(String)
}

@MainActor
@Observable
final class AuthService {
    private(set) var phase: AuthPhase = .unknown
    private(set) var session: Session?
    var pendingInviteToken: String?
    var linkError: AuthFlowError?
    var needsHandoff = false

    var userID: UUID? { session?.user.id }
    var email: String? { session?.user.email }

    private var listener: Task<Void, Never>?

    func startListening() {
        guard listener == nil else { return }
        guard let client = KKSupabase.client else {
            phase = .signedOut
            return
        }
        listener = Task { [weak self] in
            for await (_, session) in client.auth.authStateChanges {
                guard let self, !Task.isCancelled else { return }
                let previous = self.phase
                self.session = session
                self.phase = session == nil ? .signedOut : .signedIn
                if session != nil {
                    self.linkError = nil
                    if previous == .signedOut {
                        self.needsHandoff = true
                    }
                } else {
                    self.needsHandoff = false
                }
            }
        }
    }

    func sendMagicLink(email: String) async throws {
        guard let client = KKSupabase.client else { throw AuthFlowError.missingConfig }
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: InviteURL.authCallback
        )
    }

    func handleOpenURL(_ url: URL) async {
        if let token = InviteURL.token(from: url) {
            pendingInviteToken = token
            return
        }
        guard InviteURL.isAuthCallback(url) || url.scheme == InviteURL.scheme else { return }
        guard let client = KKSupabase.client else {
            linkError = .missingConfig
            return
        }
        do {
            let wasSignedIn = phase == .signedIn
            try await client.auth.session(from: url)
            linkError = nil
            if !wasSignedIn {
                needsHandoff = true
            }
        } catch {
            linkError = .expiredLink
        }
    }

    func acceptHandoff() {
        needsHandoff = false
    }

    func signOut() async {
        pendingInviteToken = nil
        linkError = nil
        needsHandoff = false
        try? await KKSupabase.client?.auth.signOut()
        session = nil
        phase = .signedOut
    }

    func clearPendingInvite() {
        pendingInviteToken = nil
    }

    static func isValidEmail(_ raw: String) -> Bool {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return false }
        let host = parts[1]
        return host.contains(".") && !host.hasPrefix(".") && !host.hasSuffix(".")
    }

    static func mapSendError(_ error: Error) -> AuthFlowError {
        if let flow = error as? AuthFlowError { return flow }
        let text = error.localizedDescription.lowercased()
        let dumped = String(describing: error).lowercased()
        if text.contains("rate") || dumped.contains("rate") || text.contains("429") {
            return .rateLimited
        }
        return .message(error.localizedDescription)
    }
}

extension AuthFlowError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidEmail: "Skriv inn en gyldig e-post."
        case .rateLimited: "Vent litt og prøv igjen."
        case .expiredLink: "Lenken er utløpt."
        case .missingConfig: "Mangler tilkobling til konto."
        case .message(let text): text
        }
    }
}

extension AuthService {
    static var previewSignedOut: AuthService {
        let service = AuthService()
        service.phase = .signedOut
        return service
    }
}
