//
//  SignInController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

class SignInController: UIViewController {
    
    private let signInView = SignInView()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .interactive
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView = UIView()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var scrollViewBottomConstraint: Constraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#362E83") // Синий фон
        
        signInView.onForgotPswTapped = { [weak self] in self?.handleForgotPsw() }
        signInView.onSignInTapped = { [weak self] in self?.handleLoginTapped() }
        signInView.onSignUpTapped = { [weak self] in self?.handleSignUp() }
        
        setupUI()
        setupKeyboardHandlers()
        setupTapGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(signInView)
        view.addSubview(activityIndicator)
        
        // 1. Скролл на весь экран
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            self.scrollViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        
        // 2. Контейнер
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            // !!! САМАЯ ВАЖНАЯ СТРОКА ДЛЯ КЛИКАБЕЛЬНОСТИ !!!
            make.width.equalTo(scrollView)
        }
        
        // 3. Карточка входа
        signInView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(40) // Используем inset для отступа от низа
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Actions
    @objc private func handleLoginTapped() {
        guard let email = signInView.getRegisteredEmail(), !email.isEmpty,
              let password = signInView.getRegisteredPassword(), !password.isEmpty else {
            showErrorAlert(message: "Please enter both email and password.")
            return
        }
        
        setLoading(true)
        
        NetworkManager.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let loginResponse):
                    AuthManager.shared.saveToken(loginResponse.token)
                    
                    UserDefaults.standard.set(loginResponse.userId, forKey: "cachedUserId")
                    
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.checkAuthentication()
                    
                case .failure(let error):
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func handleForgotPsw() {
        let vc = ForgotPswController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func handleSignUp() {
        let vc = SignUpController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func setLoading(_ loading: Bool) {
        view.isUserInteractionEnabled = !loading
        signInView.alpha = loading ? 0.5 : 1.0
        if loading { activityIndicator.startAnimating() } else { activityIndicator.stopAnimating() }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard & Gestures
    private func setupKeyboardHandlers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        else { return }
        
        self.scrollViewBottomConstraint?.update(inset: keyboardFrame.height)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        else { return }
        
        self.scrollViewBottomConstraint?.update(inset: 0)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}
