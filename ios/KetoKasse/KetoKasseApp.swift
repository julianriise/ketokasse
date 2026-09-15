import SwiftUI

@main
struct KetoKasseApp: App {
    @State private var auth = AuthService()
    @State private var household = HouseholdRepository()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .environment(household)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    Task { await auth.handleOpenURL(url) }
                }
        }
    }
}
