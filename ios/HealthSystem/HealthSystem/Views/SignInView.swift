//
//  SignInView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

class SignInView: UIView {
    
    var onSignInTapped: (() -> Void)?
    var onForgotPswTapped: (() -> Void)?
    var onSignUpTapped: (() -> Void)?
        
    // MARK: - UI Components
    private let mainTitle = CustomTitleLabel(fontSize: 28, weight: .bold)
    private let subTitle = CustomSubTitleLabel(fontSize: 20, weight: .regular)
    
    private let emailField = CustomTextField(placeholder: "Email")
    private let pswField = CustomTextField(placeholder: "Password")
    
    private let signInBtn = CustomButton(backgroundColor: .init(hex: "#362E83"),
                                         titleColor: .white,
                                         title: "Sign in")
    
    private let forgotBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Forgot Password?", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(UIColor(hex: "#33415C"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return button
    }()
    
    private let signUpBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Don't have an account? Sign Up", for: .normal)
        button.backgroundColor = .clear
        button.setTitleColor(UIColor(hex: "#33415C"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return button
    }()
    
    // MARK: - LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white // Возвращаем белый фон
        layer.cornerRadius = 10
        
        // Тень для красоты
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
    
    // MARK: - UI Setup
    private func setupStyles() {
        // Гарантируем черный текст
        emailField.textColor = .black
        pswField.textColor = .black
        
        // Настраиваем Placeholder
        emailField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [.foregroundColor: UIColor.gray])
        pswField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [.foregroundColor: UIColor.gray])
    }

    private func configure() {
        addSubviews(mainTitle, subTitle, emailField, pswField, signInBtn, forgotBtn, signUpBtn)
        
        mainTitle.textColor = .black
        mainTitle.text = "Let’s plan trips with Travel Planner!"
        mainTitle.numberOfLines = 0
        mainTitle.textAlignment = .center
        
        mainTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        subTitle.text = "Discover the World with Every Sign In"
        subTitle.numberOfLines = 0
        subTitle.textAlignment = .center
        
        subTitle.snp.makeConstraints { make in
            make.top.equalTo(mainTitle.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        emailField.snp.makeConstraints { make in
            make.top.equalTo(subTitle.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        // ВАЖНО: Мы убрали addTarget с lowercased!
        
        pswField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        pswField.isSecureTextEntry = true
        
        forgotBtn.snp.makeConstraints { make in
            make.top.equalTo(pswField.snp.bottom).offset(12)
            make.trailing.equalToSuperview().inset(16)
        }
        forgotBtn.addTarget(self, action: #selector(didTapForgotPsw), for: .touchUpInside)
        
        signInBtn.snp.makeConstraints { make in
            make.top.equalTo(forgotBtn.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        signInBtn.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        
        signUpBtn.snp.makeConstraints { make in
            make.top.equalTo(signInBtn.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            // КРИТИЧЕСКИ ВАЖНО: Этот констрейнт задает высоту всей карточки
            make.bottom.equalToSuperview().inset(32)
        }
        signUpBtn.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
    }
    
    // MARK: - Selectors
    @objc private func didTapForgotPsw() { onForgotPswTapped?() }
    @objc private func didTapSignIn() { onSignInTapped?() }
    @objc private func didTapSignUp() { onSignUpTapped?() }

    func getRegisteredEmail() -> String? {
        // Lowercase делаем только ПРИ ОТПРАВКЕ
        return emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    func getRegisteredPassword() -> String? {
        return pswField.text
    }
}
