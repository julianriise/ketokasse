import Foundation
import Supabase

enum KKSupabase {
    static let client: SupabaseClient? = {
        guard let config = loadConfig() else { return nil }
        return SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
    }()

    static func loadConfig() -> (url: URL, anonKey: String)? {
        let info = Bundle.main.infoDictionary
        guard
            let urlString = info?["SUPABASE_URL"] as? String,
            let url = URL(string: urlString),
            let key = info?["SUPABASE_ANON_KEY"] as? String
        else { return nil }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty, !trimmed.isEmpty, trimmed != "REPLACE_ME" else { return nil }
        return (url, trimmed)
    }
}
