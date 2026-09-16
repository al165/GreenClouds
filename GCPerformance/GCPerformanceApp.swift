import SwiftUI

@main
struct GCPerformanceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            PerformanceRootView()
                .statusBarHidden(true)
                .preferredColorScheme(.light)
        }
    }
}
