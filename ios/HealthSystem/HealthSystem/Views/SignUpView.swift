//
//  SignUpView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

class SignUpView: UIView {
    
    var onSignUpTapped: (() -> Void)?
    var onSignInTapped: (() -> Void)?
    var onLinkTapped: ((String) -> Void)?
    
    // MARK: - UI Components
    private let mainTitle = CustomTitleLabel(fontSize: 28, weight: .bold)
    private let subTitle = CustomSubTitleLabel(fontSize: 20, weight: .regular)
    
    private let nameField = CustomTextField(placeholder: "Name")
    private let surnameField = CustomTextField(placeholder: "Surname")
    private let emailField = CustomTextField(placeholder: "Email")
    private let pswField = CustomTextField(placeholder: "Password")
    private let confPswField = CustomTextField(placeholder: "Confirm Password")
    
    private let signUpBtn = CustomButton(backgroundColor: .init(hex: "#362E83"),
                                         titleColor: .white,
                                         title: "Sign Up")
    
    private let signInBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Already have an account? Sign In", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(UIColor(hex: "#33415C"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return button
    }()
    
    private let termsTextView: UITextView = {
        let attributedString = NSMutableAttributedString(string: "By creating an account, you agree to our Terms & Conditions and you acknowledge that you have read our Privacy Policy")
        attributedString.addAttribute(.link, value: "terms://termsAndConditions", range: (attributedString.string as NSString).range(of: "Terms & Conditions"))
        
        attributedString.addAttribute(.link, value: "privacy://privacyPolicy", range: (attributedString.string as NSString).range(of: "Privacy Policy"))
        
        let textView = UITextView()
        textView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue]
        textView.backgroundColor = .clear
        textView.attributedText = attributedString
        textView.textColor = .gray // Серый текст соглашения
        textView.isSelectable = true
        textView.isEditable = false
        textView.delaysContentTouches = false
        textView.isScrollEnabled = false
        textView.textAlignment = .center
        return textView
    }()
    
    // MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 10
        
        // Тени
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10
        
        configure()
        setupStyles()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStyles() {
        // Делаем текст черным
        [nameField, surnameField, emailField, pswField, confPswField].forEach {
            $0.textColor = .black
            $0.attributedPlaceholder = NSAttributedString(string: $0.placeholder ?? "", attributes: [.foregroundColor: UIColor.gray])
        }
    }
    
    // MARK: - UI Setup
    
    private func configure() {
        addSubviews(mainTitle, subTitle, nameField, surnameField, emailField, pswField, confPswField, signUpBtn, signInBtn, termsTextView)
        
        mainTitle.text = "Let’s plan trips with Travel Planner!"
        mainTitle.textColor = .black
        mainTitle.numberOfLines = 0
        mainTitle.textAlignment = .center
        
        mainTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        subTitle.text = "Discover the World with Every Sign Up"
        subTitle.textColor = .gray
        subTitle.numberOfLines = 0
        subTitle.textAlignment = .center
        
        subTitle.snp.makeConstraints { make in
            make.top.equalTo(mainTitle.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        // --- Fields ---
        nameField.snp.makeConstraints { make in
            make.top.equalTo(subTitle.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        surnameField.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        emailField.snp.makeConstraints { make in
            make.top.equalTo(surnameField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        // УБРАЛИ addTarget lowercased!
        
        pswField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        pswField.isSecureTextEntry = true
        
        confPswField.snp.makeConstraints { make in
            make.top.equalTo(pswField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        confPswField.isSecureTextEntry = true
        
        // --- Buttons ---
        signUpBtn.snp.makeConstraints { make in
            make.top.equalTo(confPswField.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        signUpBtn.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
        
        termsTextView.snp.makeConstraints { make in
            make.top.equalTo(signUpBtn.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        termsTextView.delegate = self
        
        signInBtn.snp.makeConstraints { make in
            make.top.equalTo(termsTextView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            
            // !!! ВОТ ЭТОГО НЕ ХВАТАЛО !!!
            // Привязка к низу. Теперь View знает свою высоту.
            make.bottom.equalToSuperview().inset(32)
        }
        signInBtn.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
    }
    
    // MARK: - Selectors
    @objc private func didTapSignUp() { onSignUpTapped?() }
    @objc private func didTapSignIn() { onSignInTapped?() }
    
    func getName() -> String? { return nameField.text }
    func getSurname() -> String? { return surnameField.text }
    
    func getEmail() -> String? {
        // Lowercase делаем тут
        return emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    func getPassword() -> String? { return pswField.text }
    func getConfirmPassword() -> String? { return confPswField.text }
}

extension SignUpView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "terms" {
            onLinkTapped?("https://policies.google.com/terms?hl=en-US")
        } else if URL.scheme == "privacy" {
            onLinkTapped?("https://policies.google.com/privacy?hl=en-US")
        }
        return false
    }
}
