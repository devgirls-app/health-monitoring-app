//
//  ResetPasswordController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 17/11/25.
//

import UIKit
import SnapKit

class ResetPasswordController: UIViewController {

    // MARK: - Properties
    
    private let token: String
    
    private let resetPasswordView = ResetPasswordView()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemGray // Изменено с .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Init
    
    init(token: String) {
        self.token = token
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // hex: "#362E83"
        
        resetPasswordView.onSavePasswordTapped = { [weak self] in
            self?.handleSavePassword()
        }
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.tintColor = .systemBlue
        self.title = "Reset Password"
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(handleClose))
        }
    }
    
    @objc private func handleClose() {
        dismiss(animated: true, completion: nil)
    }

    private func setupUI() {
        view.addSubview(resetPasswordView)
        resetPasswordView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func handleSavePassword() {
        guard let newPassword = resetPasswordView.getNewPassword(), !newPassword.isEmpty else {
            showErrorAlert(message: "Please enter a new password.")
            return
        }
        
        guard let confirmPassword = resetPasswordView.getConfirmPassword(), newPassword == confirmPassword else {
            showErrorAlert(message: "Passwords do not match.")
            return
        }
        
        if newPassword.count < 6 {
            showErrorAlert(message: "Password must be at least 6 characters long.")
            return
        }
        
        setLoading(true)
        
        NetworkManager.shared.resetPassword(token: self.token, newPassword: newPassword) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                switch result {
                case .success:
                    let alert = UIAlertController(title: "Success", message: "Your password has been updated. Please sign in.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self?.navigationController?.popToRootViewController(animated: true)
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    self?.present(alert, animated: true)
                    
                case .failure(let error):
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    
    private func setLoading(_ loading: Bool) {
        resetPasswordView.isUserInteractionEnabled = !loading
        resetPasswordView.alpha = loading ? 0.7 : 1.0
        
        if loading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func showErrorAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
