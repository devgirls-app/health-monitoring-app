//
//  ResetPasswordView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 17/11/25.
//

import UIKit
import SnapKit

class ResetPasswordView: UIView {
    
    // MARK: - Callbacks
    
    var onSavePasswordTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let mainTitle = CustomTitleLabel(fontSize: 28,
                                               weight: .bold)
    
    private let subTitle = CustomSubTitleLabel(fontSize: 20,
                                                 weight: .regular)
    
    private let newPswField = CustomTextField(placeholder: "New Password")
    
    private let confirmPswField = CustomTextField(placeholder: "Confirm New Password")

    private let saveBtn = CustomButton(backgroundColor: .init(hex: "#362E83"),
                                       titleColor: .white,
                                       title: "Save New Password")
    
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
        addSubviews(mainTitle, subTitle, newPswField, confirmPswField, saveBtn)
        
        mainTitle.text = "Set New Password"
        mainTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        subTitle.text = "Please enter and confirm your new password."
        subTitle.snp.makeConstraints { make in
            make.top.equalTo(mainTitle.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        newPswField.snp.makeConstraints { make in
            make.top.equalTo(subTitle.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(11)
            make.height.equalTo(48)
        }
        newPswField.isSecureTextEntry = true
        newPswField.textContentType = .newPassword
        
        confirmPswField.snp.makeConstraints { make in
            make.top.equalTo(newPswField.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(11)
            make.height.equalTo(48)
        }
        confirmPswField.isSecureTextEntry = true
        confirmPswField.textContentType = .newPassword
        
        saveBtn.snp.makeConstraints { make in
            make.top.equalTo(confirmPswField.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(11)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().inset(32) // Важно
        }
        saveBtn.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
    }
    
    // MARK: - Selectors
    
    @objc private func didTapSave() {
        onSavePasswordTapped?()
    }

    // MARK: - Public Methods
    
    func getNewPassword() -> String? {
        return newPswField.text
    }
    
    func getConfirmPassword() -> String? {
        return confirmPswField.text
    }
}
