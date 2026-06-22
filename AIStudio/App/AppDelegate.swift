import UIKit
import ApphudSDK

@main

// MARK: - AppDelegate
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        #if DEBUG
        Apphud.enableDebugLogs()
        #endif
        Apphud.start(apiKey: AppConfig.Apphud.apiKey)
        Apphud.setDelegate(AppServices.subscription)
        AppServices.userIdentifier.refresh()
        return true
    }
}
