import UIKit
import ApphudSDK

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Start Apphud BEFORE any UI is built (SceneDelegate runs after this), so
        // `Apphud.userID()` is available for the very first network request and
        // subscription state is known up front.
        Apphud.start(apiKey: AppConfig.Apphud.apiKey)
        Apphud.setDelegate(AppServices.subscription)
        // Capture Apphud's user id (main-actor API) so it's ready for the first
        // network request and cached for off-main reads.
        AppServices.userIdentifier.refresh()
        return true
    }
}
