import SwiftUI
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct PuebloApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = MarketplaceStore(repository: DemoMarketplaceRepository())
    @State private var auth = AuthStore()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(store)
                .environment(auth)
                .tint(AppTheme.coral)
        }
    }
}
