import Foundation
import UIKit

struct HealthRecommendation: Codable {
    let recId: Int
    let recommendationText: String
    let source: String?
    let severity: String?
    let createdAt: [Int]?
    let userId: Int?
}
