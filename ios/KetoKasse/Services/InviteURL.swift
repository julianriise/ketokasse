import Foundation

enum InviteURL {
    static let siteHost = "ketokasse-site.vercel.app"
    static let scheme = "ketokasse"
    static let authCallback = URL(string: "ketokasse://auth-callback")!

    static func webJoin(_ token: String) -> URL {
        URL(string: "https://\(siteHost)/join/\(token)")!
    }

    static func appJoin(_ token: String) -> URL {
        URL(string: "\(scheme)://join/\(token)")!
    }

    static func token(from url: URL) -> String? {
        if url.scheme == scheme {
            if url.host == "join" {
                return validToken(url.path.split(separator: "/").first.map(String.init))
            }
            let parts = url.path.split(separator: "/").map(String.init)
            if parts.first == "join", parts.count >= 2 {
                return validToken(parts[1])
            }
        }
        if url.host == siteHost {
            let parts = url.path.split(separator: "/").map(String.init)
            if parts.first == "join", parts.count >= 2 {
                return validToken(parts[1])
            }
        }
        return nil
    }

    static func isAuthCallback(_ url: URL) -> Bool {
        if url.scheme == scheme, url.host == "auth-callback" {
            return true
        }
        if token(from: url) != nil {
            return false
        }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if items.contains(where: { $0.name == "code" && ($0.value?.isEmpty == false) }) {
            return true
        }
        if url.fragment?.contains("access_token") == true {
            return true
        }
        return false
    }

    private static func validToken(_ token: String?) -> String? {
        guard let token, !token.isEmpty else { return nil }
        return token
    }
}
