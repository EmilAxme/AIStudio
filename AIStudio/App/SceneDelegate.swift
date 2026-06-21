import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let navigationController = UINavigationController(rootViewController: HomeViewController())
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.view.backgroundColor = AppColor.background

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.overrideUserInterfaceStyle = .dark
        window.makeKeyAndVisible()
        self.window = window

        #if DEBUG
        routeForUITestingIfNeeded(in: navigationController)
        #endif
    }

    #if DEBUG
    /// Debug-only deep link used to launch the app straight into a given screen
    /// (e.g. `-INITIAL_SCREEN chat`). Lets snapshots/QA reach any screen without
    /// driving the UI; compiled out of Release builds.
    private func routeForUITestingIfNeeded(in nav: UINavigationController) {
        guard let screen = UserDefaults.standard.string(forKey: "INITIAL_SCREEN") else { return }
        switch screen {
        case "chat":
            nav.pushViewController(ChatViewController(), animated: false)
        case "chatEmpty":
            nav.pushViewController(ChatViewController(startEmpty: true), animated: false)
        case "chatHistory":
            nav.pushViewController(HistoryViewController.chat(), animated: false)
        case "chatHistoryEmpty":
            nav.pushViewController(HistoryViewController.chat(empty: true), animated: false)
        case "videoHistory":
            nav.pushViewController(HistoryViewController.video(), animated: false)
        case "videoHistoryEmpty":
            nav.pushViewController(HistoryViewController.video(empty: true), animated: false)
        case "videoGallery":
            nav.pushViewController(VideoGalleryViewController(), animated: false)
        case "videoCreate":
            nav.pushViewController(VideoCreateViewController(), animated: false)
        case "videoResult":
            nav.pushViewController(VideoResultViewController(request: VideoRequest(prompt: "Astro Duo", imageName: "AstroGirl", aspectRatio: "16:9", quality: "1080p")), animated: false)
        case "paywall":
            DispatchQueue.main.async {
                let paywall = PaywallViewController()
                paywall.modalPresentationStyle = .fullScreen
                nav.present(paywall, animated: false)
            }
        default:
            break
        }
    }
    #endif
}
