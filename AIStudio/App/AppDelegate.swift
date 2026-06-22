import UIKit
import ApphudSDK

@main

// MARK: - AppDelegate
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Apphud.start(apiKey: AppConfig.Apphud.apiKey)
        Apphud.setDelegate(AppServices.subscription)
        AppServices.userIdentifier.refresh()
        return true
    }
}
