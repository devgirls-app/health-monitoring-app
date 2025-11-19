//
//  AuthModels.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 17/11/25.
//

import Foundation

struct LoginResponse: Codable {
    let token: String
}

struct RegisterRequest: Codable {
    let name: String
    let surname: String
    let email: String
    let password: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let newPassword: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}
