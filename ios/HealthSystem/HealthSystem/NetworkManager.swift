//
//  NetworkManager.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 22/10/25.
//

// Network/NetworkManager.swift
import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    static let baseURL: URL = {
        
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "ApiBaseUrl") as? String else {
            fatalError("ApiBaseUrl key not found in Info.plist. Check your configuration.")
        }
        
        if urlString.contains("YOUR_") {
            fatalError("Please replace the placeholder URL in your Debug.xcconfig file.")
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("The ApiBaseUrl in Info.plist is not a valid URL: \(urlString)")
        }
        
        print("API Base URL successfully loaded: \(url)")
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
    
    func postHealthData(_ dto: HealthDataDTO, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("/phone/health-data")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            req.httpBody = try jsonEncoder.encode(dto)
        } catch { return completion(.failure(error)) }
        
        URLSession.shared.dataTask(with: req) { _, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return completion(.failure(NSError(domain: "http", code: (resp as? HTTPURLResponse)?.statusCode ?? -1)))
            }
            completion(.success(()))
        }.resume()
    }
    
    
    func fetchUserProfile(userId: Int, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("/users/\(userId)")
        URLSession.shared.dataTask(with: url) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain:"nodata", code:0))) }
            do {
                let profile = try self.jsonDecoder.decode(UserProfile.self, from: data)
                completion(.success(profile))
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    
    func runAggregate(userId: Int, date: String, completion: @escaping (Result<DailySummary, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("/aggregates/run/\(userId)/\(date)")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain:"nodata", code:0))) }
            do {
                let summary = try self.jsonDecoder.decode(DailySummary.self, from: data)
                completion(.success(summary))
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
    
    func runWeeklySummary(userId: Int, weekEnd: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = NetworkManager.baseURL.appendingPathComponent("/ml-test/weekly-fatigue/\(userId)/\(weekEnd)")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { return completion(.failure(err)) }
            guard let data = data else { return completion(.failure(NSError(domain:"nodata", code:0))) }
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = obj["message"] as? String {
                completion(.success(msg))
            } else {
                completion(.success(String(data: data, encoding: .utf8) ?? "OK"))
            }
        }.resume()
    }
}
