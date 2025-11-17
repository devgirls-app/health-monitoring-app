import Foundation

struct UserProfile: Codable {
    let userId: Int
    let name: String?
    let age: Int?
    let gender: String?
    let height: Double?
    let weight: Double?
    let recommendations: [HealthRecommendation]?
}
