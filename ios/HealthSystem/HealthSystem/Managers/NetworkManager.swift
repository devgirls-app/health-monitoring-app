//
//  NetworkManager.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 22/10/25.
//

import Foundation

enum NetworkError: Error {
    case badRequest(String?)
    case unauthorized // 401
    case forbidden // 403
    case notFound // 404
    case serverError(String?) // 500+
    case decodingError(Error)
    case noData
    case unknown(String?)
    
    var localizedDescription: String {
        switch self {
        case .badRequest(let msg): return msg ?? "Bad request"
        case .unauthorized: return "You are not authorized. Please sign in again."
        case .forbidden: return "You do not have permission."
        case .notFound: return "Resource not found."
        case .serverError(let msg): return msg ?? "Server error. Please try again later."
        case .decodingError: return "Failed to process server response."
        case .noData: return "No data received from server."
        case .unknown(let msg): return msg ?? "An unknown error occurred."
        }
    }
}


final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private static let baseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("ApiBaseUrl key not found in Info.plist. Check your configuration.")
        }
        if urlString.contains("YOUR_") {
            fatalError("Please replace the placeholder URL in your .xcconfig / Info.plist.")
        }
        guard let url = URL(string: urlString) else {
            fatalError("The API_BASE_URL in Info.plist is not a valid URL: \(urlString)")
        }
        print("🔗 API Base URL:", url.absoluteString)
        return url
    }()
    
    private let jsonEncoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
    
    private func createAuthorizedRequest(url: URL, httpMethod: String = "GET") -> URLRequest? {
        guard let token = AuthManager.shared.getToken() else {
            print("Network Error: No token found. User must login.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func handleResponse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
            print("\n--- INCOMING RESPONSE ---")
            
            if let error = error {
                print("Transport Error: \(error.localizedDescription)")
                return completion(.failure(error))
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("Error: Not HTTP response")
                return completion(.failure(NetworkError.unknown("Invalid response from server.")))
            }
            
            print("STATUS CODE: \(http.statusCode)")
            
            if let data = data, let rawString = String(data: data, encoding: .utf8) {
                print("BODY (RAW): \(rawString)")
            } else {
                print("BODY: [Empty or Binary]")
            }
            
            if http.statusCode == 401 || http.statusCode == 403 {
                print("Token expired or forbidden. Global logout initiated.")
                
                AuthManager.shared.deleteToken()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("AuthSessionExpired"), object: nil)
                }
                
                return completion(.failure(NetworkError.unauthorized))
            }
            
            guard (200..<300).contains(http.statusCode) else {
                print("Server returned error status code")
                let message = String(data: data ?? Data(), encoding: .utf8)
                
                switch http.statusCode {
                case 400: completion(.failure(NetworkError.badRequest(message)))
                case 404: completion(.failure(NetworkError.notFound))
                default: completion(.failure(NetworkError.serverError(message)))
                }
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("Error: No Data to decode")
                return completion(.failure(NetworkError.noData))
            }
            
            do {
                let decodedObject = try self.jsonDecoder.decode(T.self, from: data)
                print("Decoding Success")
                completion(.success(decodedObject))
            } catch {
                print("DECODING ERROR: \(error)")
                completion(.failure(NetworkError.decodingError(error)))
            }
            print("----------------------------\n")
        }
        
        private func handleVoidResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<Void, Error>) -> Void) {
            print("\n--- INCOMING VOID RESPONSE ---")
            
            if let error = error {
                print("Transport Error: \(error.localizedDescription)")
                return completion(.failure(error))
            }
            
            guard let http = response as? HTTPURLResponse else {
                return completion(.failure(NetworkError.unknown("Invalid response from server.")))
            }
            
            print("STATUS CODE: \(http.statusCode)")
            
            if let data = data, let rawString = String(data: data, encoding: .utf8) {
                print("BODY (RAW): \(rawString)")
            }
            
            if http.statusCode == 401 || http.statusCode == 403 {
                print("Token expired or forbidden (Void Request). Global logout initiated.")
                
                AuthManager.shared.deleteToken()
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("AuthSessionExpired"), object: nil)
                }
                
                return completion(.failure(NetworkError.unauthorized))
            }
            
            guard (200..<300).contains(http.statusCode) else {
                print("Server returned error status code")
                let message = String(data: data ?? Data(), encoding: .utf8)
                
                switch http.statusCode {
                case 400: completion(.failure(NetworkError.badRequest(message)))
                case 404: completion(.failure(NetworkError.notFound))
                default: completion(.failure(NetworkError.serverError(message)))
                }
                return
            }
            
            print("Request Successful (Void)")
            completion(.success(()))
            print("----------------------------\n")
        }
    
    
    // MARK: - Auth Endpoints (ДОБАВЛЕНО)
    
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("auth/login")
        print("POST", url.absoluteString)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        do { req.httpBody = try jsonEncoder.encode(body) }
        catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    func register(name: String, surname: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("auth/register")
        print("POST", url.absoluteString)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RegisterRequest(name: name, surname: surname, email: email, password: password)
        do { req.httpBody = try jsonEncoder.encode(body) }
        catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleVoidResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    func requestPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("password/request-reset")
        print("POST", url.absoluteString)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ForgotPasswordRequest(email: email)
        do { req.httpBody = try jsonEncoder.encode(body) }
        catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleVoidResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    func resetPassword(token: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("password/reset")
        print("POST", url.absoluteString)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ResetPasswordRequest(token: token, newPassword: newPassword)
        do { req.httpBody = try jsonEncoder.encode(body) }
        catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleVoidResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    func syncUserProfile(userId: Int, age: Int?, weight: Double?, height: Double?, gender: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let url = URL(string: "\(NetworkManager.baseURL.absoluteString)/users/\(userId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Token attached to PUT request: \(token.prefix(10))...")
        } else {
            print("No token found for syncUserProfile request!")
        }
        
        let body: [String: Any] = [
            "age": age as Any,
            "weight": weight as Any,
            "height": height as Any,
            "gender": gender as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Protected Endpoints
    
    // POST /health-data
    func postHealthData(_ dto: HealthDataDTO, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("healthdata")
        print("POST", url.absoluteString)
        
        guard var req = createAuthorizedRequest(url: url, httpMethod: "POST") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        
        do { req.httpBody = try jsonEncoder.encode(dto) }
        catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleVoidResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    // GET /users/{id}
    func fetchUserProfile(userId: Int, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("users/\(userId)")
        print("GET", url.absoluteString)
        
        guard let req = createAuthorizedRequest(url: url, httpMethod: "GET") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    // POST /aggregates/run/{userId}/{date}
    func runAggregate(userId: Int, date: String, completion: @escaping (Result<DailySummary, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("aggregates/run/\(userId)/\(date)")
        print("POST", url.absoluteString)
        
        guard let req = createAuthorizedRequest(url: url, httpMethod: "POST") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            self.handleResponse(data: data, response: resp, error: err, completion: completion)
        }.resume()
    }
    
    // POST /ml-test/weekly-fatigue/{userId}/{weekEnd}
    func runWeeklySummary(userId: Int, weekEnd: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("ml-test/weekly-fatigue/\(userId)/\(weekEnd)")
        print("POST", url.absoluteString)
        
        guard let req = createAuthorizedRequest(url: url, httpMethod: "POST") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return completion(.failure(NetworkError.unknown("Failed to run summary")))
            }
            
            guard let data = data else { return completion(.failure(NetworkError.noData)) }
            
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = obj["message"] as? String {
                completion(.success(msg))
            } else {
                completion(.success(String(data: data, encoding: .utf8) ?? "OK"))
            }
        }.resume()
    }
}
