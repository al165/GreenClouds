import SwiftUI

@main
struct GCInstallationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(true)
                .preferredColorScheme(.light)
        }
    }
}
