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
            selector: #selector(handleSessionExpired),
            name: NSNotification.Name("AuthSessionExpired"),
            object: nil
        )
        
        self.checkAuthentication()
    
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(url: urlContext.url)
        }
    }
    
    @objc private func handleSessionExpired() {
        print("Session expired notification received. Switching to SignInController.")
        self.goToController(with: SignInController())
    }
    
    private func setUpWindow(with scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        self.window?.makeKeyAndVisible()
    }
    
    public func checkAuthentication() {
        if AuthManager.shared.isAuthenticated {
            self.goToController(with: MainTabBarController())
        } else {
            self.goToController(with: SignInController())
        }
    }
    
    private func goToController(with viewController: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25) {
                self?.window?.layer.opacity = 0
            } completion: { [weak self] _ in
                
                let nav = UINavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .fullScreen
                self?.window?.rootViewController = nav
                
                UIView.animate(withDuration: 0.25) {[weak self] in
                    self?.window?.layer.opacity = 1
                }
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        handleDeepLink(url: urlContext.url)
    }
    
    private func handleDeepLink(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.host == "reset-password",
              let tokenItem = components.queryItems?.first(where: { $0.name == "token" }),
              let token = tokenItem.value else {
            return
        }
        
        print("Received deep link with token: \(token)")
        
        DispatchQueue.main.async {
            let resetVC = ResetPasswordController(token: token)
            
            if let rootNav = self.window?.rootViewController as? UINavigationController {
                if rootNav.topViewController is MainTabBarController {
                    rootNav.pushViewController(resetVC, animated: true)
                } else {
                    rootNav.present(UINavigationController(rootViewController: resetVC), animated: true)
                }
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self)
    }
}
