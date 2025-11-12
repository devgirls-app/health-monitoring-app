import Foundation

struct DailySummary: Codable {
    let aggId: Int?
    let userId: Int?
    let date: [Int]?
    let stepsTotal: Int?
    let caloriesTotal: Double?
    let hrMean: Double?
    let hrMax: Int?
    let sleepHoursTotal: Double?
}
