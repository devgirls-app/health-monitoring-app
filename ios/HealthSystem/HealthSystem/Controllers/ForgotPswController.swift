//
//  ForgotPswController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

class ForgotPswController: UIViewController {

    private let forgotPswView = ForgotPswView()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemGray
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        forgotPswView.onSendLinkTapped = { [weak self] in
            self?.handleSendLink()
        }
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.tintColor = .systemBlue
        self.title = "Forgot Password"
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black] // Изменено с .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }

    private func setupUI() {
        view.addSubview(forgotPswView)
        forgotPswView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func handleSendLink() {
        guard let email = forgotPswView.getEmail(), !email.isEmpty else {
            showErrorAlert(message: "Please enter your email.")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            showErrorAlert(message: "Please enter a valid email address.")
            return
        }
        
        setLoading(true)
        
        NetworkManager.shared.requestPasswordReset(email: email) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                switch result {
                case .success:
                    self?.showErrorAlert(title: "Success", message: "If your email is registered, you will receive a password reset link shortly.")
                case .failure(let error):
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
        
    private func setLoading(_ loading: Bool) {
        forgotPswView.isUserInteractionEnabled = !loading
        forgotPswView.alpha = loading ? 0.7 : 1.0
        
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
