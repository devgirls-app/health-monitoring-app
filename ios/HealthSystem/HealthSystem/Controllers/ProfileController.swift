//
//  ProfileController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 3/11/25.
//

import UIKit
import SnapKit

final class ProfileController: UIViewController {
    
    // MARK: - Inputs
    private var userId: Int {
        return AuthManager.shared.getUserId() ?? 0
    }
    
    // MARK: - View
    private let profileView = ProfileView()
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = profileView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfileData()
    }
    
    private func setupActions() {
        profileView.logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }
    
    // MARK: - Networking
    private func fetchProfileData() {
        profileView.setLoading(true)
        
        NetworkManager.shared.fetchUserProfile(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.profileView.setLoading(false)
                
                switch result {
                case .success(let user):
                    self?.profileView.updateUI(with: user)
                case .failure(let error):
                    print("Error loading profile: \(error)")
                    self?.profileView.updateUI(with: nil)
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func didTapLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
            AuthManager.shared.deleteToken()
            NotificationCenter.default.post(name: NSNotification.Name("AuthSessionExpired"), object: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}
