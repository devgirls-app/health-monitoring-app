//
//  SignUpController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

class SignUpController: UIViewController {
    
    private let signUpView = SignUpView()
    
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
        view.backgroundColor = UIColor(hex: "#362E83")
        
        signUpView.onSignInTapped = { [weak self] in self?.handleSignIn() }
        signUpView.onSignUpTapped = { [weak self] in self?.handleSignUp() }
        signUpView.onLinkTapped = { [weak self] urlString in self?.showWebViewer(with: urlString) }
        
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
        contentView.addSubview(signUpView)
        view.addSubview(activityIndicator)
        
        // 1. ScrollView
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            self.scrollViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        
        // 2. ContentView
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            // !!! ВАЖНО: Ширина равна ширине скролла !!!
            make.width.equalTo(scrollView)
        }
        
        // 3. SignUpView
        signUpView.snp.makeConstraints { make in
            // Отступ сверху чуть меньше, чтобы влезло на маленькие экраны
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            // Отступ снизу (inset)
            make.bottom.equalToSuperview().inset(40)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Validation & Actions
    
    private func validateFields(name: String, surname: String, email: String, psw: String, confPsw: String) -> String? {
        if name.isEmpty || surname.isEmpty || email.isEmpty || psw.isEmpty {
            return "Please fill in all fields."
        }
        if !email.contains("@") {
            return "Invalid email."
        }
        if psw.count < 6 {
            return "Password must be at least 6 characters."
        }
        if psw != confPsw {
            return "Passwords do not match."
        }
        return nil
    }
    
    private func handleSignUp() {
        let name = signUpView.getName() ?? ""
        let surname = signUpView.getSurname() ?? ""
        let email = signUpView.getEmail() ?? ""
        let password = signUpView.getPassword() ?? ""
        let confPassword = signUpView.getConfirmPassword() ?? ""
        
        if let validationError = validateFields(name: name, surname: surname, email: email, psw: password, confPsw: confPassword) {
            showErrorAlert(title: "Validation Error", message: validationError)
            return
        }
        
        setLoading(true)
        
        NetworkManager.shared.register(name: name, surname: surname, email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                print("Registration successful. Logging in...")
                self.loginUser(email: email, password: password)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.setLoading(false)
                    self.showErrorAlert(message: "Registration Failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loginUser(email: String, password: String) {
        NetworkManager.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let loginResponse):
                    AuthManager.shared.saveToken(loginResponse.token)
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.checkAuthentication()
                case .failure(let error):
                    self?.showErrorAlert(title: "Success", message: "Account created, but login failed. Please login manually. \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleSignIn() {
        navigationController?.popViewController(animated: true)
    }
    
    private func showWebViewer(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func setLoading(_ loading: Bool) {
        signUpView.isUserInteractionEnabled = !loading
        signUpView.alpha = loading ? 0.5 : 1.0
        if loading { activityIndicator.startAnimating() } else { activityIndicator.stopAnimating() }
    }
    
    private func showErrorAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
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
