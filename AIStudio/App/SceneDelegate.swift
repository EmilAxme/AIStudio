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
    }
}
