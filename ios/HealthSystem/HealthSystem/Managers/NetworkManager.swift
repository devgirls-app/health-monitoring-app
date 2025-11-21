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
    
    static let baseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("ApiBaseUrl key not found in Info.plist.")
        }
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL: \(urlString)")
        }
        return url
    }()
    
    public func getBaseURLString() -> String {
        return NetworkManager.baseURL.absoluteString
    }
    
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
            print("Network Error: No token found.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    // MARK: - Handle Response (GENERIC)
    private func handleResponse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        
        // Helper to ensure main thread execution
        let safeCompletion: (Result<T, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        print("\n--- INCOMING RESPONSE ---")
        if let error = error {
            return safeCompletion(.failure(error))
        }
        
        guard let http = response as? HTTPURLResponse else {
            return safeCompletion(.failure(NetworkError.unknown("Invalid response")))
        }
        
        print("STATUS: \(http.statusCode)")
        if let data = data, let str = String(data: data, encoding: .utf8) {
            // print("BODY: \(str)") // Uncomment for debugging full body
        }
        
        // Only logout on 401 (Unauthorized)
        if http.statusCode == 401 {
            print("🔒 401 Unauthorized. Logging out...")
            AuthManager.shared.deleteToken()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("AuthSessionExpired"), object: nil)
            }
            return safeCompletion(.failure(NetworkError.unauthorized))
        }
        
        // For 403 and others, just return failure without logging out
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data ?? Data(), encoding: .utf8)
            
            if http.statusCode == 403 {
                print("⚠️ 403 Forbidden received. Request failed, but session is kept active.")
                return safeCompletion(.failure(NetworkError.forbidden))
            }
            if http.statusCode == 404 { return safeCompletion(.failure(NetworkError.notFound)) }
            if http.statusCode == 400 { return safeCompletion(.failure(NetworkError.badRequest(msg))) }
            
            return safeCompletion(.failure(NetworkError.serverError(msg)))
        }
        
        guard let data = data, !data.isEmpty else {
            return safeCompletion(.failure(NetworkError.noData))
        }
        
        do {
            let decoded = try self.jsonDecoder.decode(T.self, from: data)
            print("Decoding Success")
            safeCompletion(.success(decoded))
        } catch {
            print("Decoding Error: \(error)")
            safeCompletion(.failure(NetworkError.decodingError(error)))
        }
        print("----------------------------\n")
    }
    
    // MARK: - Handle Void Response
    private func handleVoidResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<Void, Error>) -> Void) {
        let safeCompletion: (Result<Void, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        print("\n--- INCOMING VOID RESPONSE ---")
        if let error = error {
            return safeCompletion(.failure(error))
        }
        
        guard let http = response as? HTTPURLResponse else {
            return safeCompletion(.failure(NetworkError.unknown("Invalid response")))
        }
        
        print("STATUS: \(http.statusCode)")
        
        if http.statusCode == 401 {
            print("🔒 401 Unauthorized (Void). Logging out...")
            AuthManager.shared.deleteToken()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("AuthSessionExpired"), object: nil)
            }
            return safeCompletion(.failure(NetworkError.unauthorized))
        }
        
        guard (200..<300).contains(http.statusCode) || http.statusCode == 202 else {
            let msg = String(data: data ?? Data(), encoding: .utf8)
            
            if http.statusCode == 403 {
                print("⚠️ 403 Forbidden (Void). Request failed, but session is kept active.")
                return safeCompletion(.failure(NetworkError.forbidden))
            }
            
            if http.statusCode == 400 { return safeCompletion(.failure(NetworkError.badRequest(msg))) }
            if http.statusCode == 404 { return safeCompletion(.failure(NetworkError.notFound)) }
            
            return safeCompletion(.failure(NetworkError.serverError(msg)))
        }
        
        print("Request Successful (Void)")
        safeCompletion(.success(()))
        print("----------------------------\n")
    }
    
    // MARK: - Endpoints
    
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("auth/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        do { req.httpBody = try jsonEncoder.encode(body) } catch { completion(.failure(error)); return }
        
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func register(name: String, surname: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("auth/register")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = RegisterRequest(name: name, surname: surname, email: email, password: password)
        do { req.httpBody = try jsonEncoder.encode(body) } catch { completion(.failure(error)); return }
        
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleVoidResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func requestPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("password/request-reset")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ForgotPasswordRequest(email: email)
        do { req.httpBody = try jsonEncoder.encode(body) } catch { completion(.failure(error)); return }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleVoidResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func resetPassword(token: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("password/reset")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ResetPasswordRequest(token: token, newPassword: newPassword)
        do { req.httpBody = try jsonEncoder.encode(body) } catch { completion(.failure(error)); return }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleVoidResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    // MARK: - User & Health Data Endpoints
    
    func syncUserProfile(userId: Int, age: Int?, weight: Double?, height: Double?, gender: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("users/\(userId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "age": age as Any,
            "weight": weight as Any,
            "height": height as Any,
            "gender": gender as Any
        ]
        do { request.httpBody = try JSONSerialization.data(withJSONObject: body, options: []) }
        catch { completion(.failure(error)); return }
        
        URLSession.shared.dataTask(with: request) { d, r, e in self.handleVoidResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func postHealthData(_ dto: HealthDataDTO, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("ingest/health-data")
        guard var req = createAuthorizedRequest(url: url, httpMethod: "POST") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        do { req.httpBody = try jsonEncoder.encode(dto) } catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleVoidResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func fetchUserProfile(userId: Int, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("users/\(userId)")
        guard let req = createAuthorizedRequest(url: url, httpMethod: "GET") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    // MARK: - ML & Aggregation Endpoints
    
    func runAggregate(userId: Int, date: String, completion: @escaping (Result<DailySummary, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("aggregates/run/\(userId)/\(date)")
        guard let req = createAuthorizedRequest(url: url, httpMethod: "POST") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func fetchRecommendations(completion: @escaping (Result<[HealthRecommendation], Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("recommendations")
        guard let req = createAuthorizedRequest(url: url, httpMethod: "GET") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func fetchTrends(userId: Int, days: Int = 7, completion: @escaping (Result<[DailySummary], Error>) -> Void) {
        let path = "aggregates/history/\(userId)"
        guard var comps = URLComponents(url: NetworkManager.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else { return }
        comps.queryItems = [URLQueryItem(name: "days", value: String(days))]
        guard let url = comps.url, let req = createAuthorizedRequest(url: url, httpMethod: "GET") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
    
    func debugTriggerWeeklySummary(userId: Int, date: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("ml-test/weekly-fatigue/\(userId)/\(date)")
        guard let req = createAuthorizedRequest(url: url, httpMethod: "GET") else {
            return completion(.failure(NetworkError.unauthorized))
        }
        URLSession.shared.dataTask(with: req) { d, r, e in self.handleVoidResponse(data: d, response: r, error: e, completion: completion) }.resume()
    }
}
