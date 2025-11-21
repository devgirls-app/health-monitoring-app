//
//  SceneDelegate.swift
//  HealthSystem
//
//  Created by Elina Karimova on 15/10/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.setUpWindow(with: scene)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: NSNotification.Name("AuthSessionExpired"),
            object: nil
        )
        
        validateSessionAndStart()
    
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(url: urlContext.url)
        }
    }
    
    // MARK: - Start Logic (Cold Start)
    
    private func validateSessionAndStart() {
        guard AuthManager.shared.isAuthenticated, let userId = AuthManager.shared.getUserId() else {
            self.goToController(with: SignInController())
            return
        }
        
        let splashVC = UIViewController()
        splashVC.view.backgroundColor = .systemBackground
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        splashVC.view.addSubview(spinner)
        spinner.center = splashVC.view.center
        
        window?.rootViewController = splashVC
        
        print("🔍 Validating token with server...")
        NetworkManager.shared.fetchUserProfile(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print(" Token is valid. Starting app.")
                    self?.goToController(with: MainTabBarController())
                case .failure:
                    print(" Token invalid or user deleted. Resetting session.")
                    AuthManager.shared.deleteToken()
                    self?.goToController(with: SignInController())
                }
            }
        }
    }
    
    // MARK: - Auth Routing
    
    public func checkAuthentication() {
        if AuthManager.shared.isAuthenticated {
            self.goToController(with: MainTabBarController())
        } else {
            self.goToController(with: SignInController())
        }
    }
    
    @objc private func handleLogout() {
        DispatchQueue.main.async {
            self.goToController(with: SignInController())
        }
    }
    
    // MARK: - Navigation Helper
    
    private func setUpWindow(with scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        self.window?.makeKeyAndVisible()
    }
    
    private func goToController(with viewController: UIViewController) {
        guard let window = self.window else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            if let tabBar = viewController as? UITabBarController {
                window.rootViewController = tabBar
            } else {
                let nav = UINavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .fullScreen
                window.rootViewController = nav
            }
        }, completion: nil)
    }

    // MARK: - Deep Linking
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        handleDeepLink(url: urlContext.url)
    }
    
    private func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.host == "reset-password",
              let tokenItem = components.queryItems?.first(where: { $0.name == "token" }),
              let token = tokenItem.value else { return }
        
        DispatchQueue.main.async {
            let resetVC = ResetPasswordController(token: token)
            if let root = self.window?.rootViewController {
                root.present(UINavigationController(rootViewController: resetVC), animated: true)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self)
    }
}
