//
//  ForgotPswView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

import UIKit
import SnapKit

class ForgotPswView: UIView {
    
    // MARK: - Callbacks
    
    var onSendLinkTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let mainTitle = CustomTitleLabel(fontSize: 28,
                                               weight: .bold)
    
    private let subTitle = CustomSubTitleLabel(fontSize: 20,
                                                 weight: .regular)
    
    private let emailField = CustomTextField(placeholder: "Email")
    
    private let sendLinkBtn = CustomButton(backgroundColor: .init(hex: "#362E83"),
                                           titleColor: .white,
                                           title: "Send Reset Link")
    
    // MARK: - LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 10
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func configure() {
        addSubviews(mainTitle, subTitle, emailField, sendLinkBtn)
        
        mainTitle.text = "Forgot Password?"
        mainTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        subTitle.text = "Enter your email to get a reset link."
        subTitle.snp.makeConstraints { make in
            make.top.equalTo(mainTitle.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        emailField.snp.makeConstraints { make in
            make.top.equalTo(subTitle.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(11)
            make.height.equalTo(48)
        }
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.addTarget(self, action: #selector(emailFieldEditingChanged(_:)), for: .editingChanged)
        
        sendLinkBtn.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(11)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().inset(32) // Важно, чтобы view имела нижнюю границу
        }
        sendLinkBtn.addTarget(self, action: #selector(didTapSendLink), for: .touchUpInside)
    }
    
    // MARK: - Selectors
    
    @objc private func emailFieldEditingChanged(_ textField: UITextField) {
        textField.text = textField.text?.lowercased()
    }
    
    @objc private func didTapSendLink() {
        onSendLinkTapped?()
    }

    // MARK: - Public Methods
    
    func getEmail() -> String? {
        return emailField.text
    }
}
