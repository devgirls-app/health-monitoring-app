//
//  AuthManager.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 17/11/25.
//

import Foundation
import Security

final class AuthManager {
    
    static let shared = AuthManager()
    
    private let serviceName = "com.HealthSystem.auth"
    private let accountName = "jwtToken"
    
    // MARK: - Public Properties
    
    var isAuthenticated: Bool {
        return getToken() != nil
    }
    
    // MARK: - Public Methods
    
    
    func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        
        deleteToken()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("AuthManager: Error saving token to Keychain, status: \(status)")
        } else {
            print("AuthManager: Token saved successfully.")
        }
    }
   
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            guard let data = dataTypeRef as? Data,
                  let token = String(data: data, encoding: .utf8) else {
                return nil
            }
            return token
        } else {
            if status != errSecItemNotFound {
                print("AuthManager: Error fetching token, status: \(status)")
            }
            return nil
        }
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("AuthManager: Error deleting token, status: \(status)")
        } else {
            print("AuthManager: Token deleted.")
        }
    }
    
    func getUserId() -> Int? {
        let id = UserDefaults.standard.integer(forKey: "cachedUserId")
        return id == 0 ? nil : id
    }
}
