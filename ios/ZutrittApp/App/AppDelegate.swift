import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Für iOS 12: Manuelle Erstellung des UIWindow (SceneDelegate existiert erst ab iOS 13)
        if #available(iOS 13.0, *) {
            // Wird von SceneDelegate übernommen
        } else {
            let win = UIWindow(frame: UIScreen.main.bounds)
            let mainVC = MainViewController()
            let nav = UINavigationController(rootViewController: mainVC)
            win.rootViewController = nav
            win.makeKeyAndVisible()
            self.window = win
        }
        
        return true
    }

    // MARK: - UISceneSession Lifecycle (iOS 13+)

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
