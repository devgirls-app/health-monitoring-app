import Foundation

struct HealthTrend: Codable {
    let date: String?
    let avgHeartRate: Double?
    let dailySteps: Int?
    let trendLabel: String?
}
