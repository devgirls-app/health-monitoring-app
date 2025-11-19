//
//  HealthModels.swift.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import Foundation
import UIKit

// MARK: - Backend DTOs
// These match your Java entities exactly.

struct HealthRecommendation: Codable {
    let recId: Int
    let recommendationText: String
    let source: String?      // e.g., "weekly_summary", "ml_model", "rules"
    let severity: String?    // e.g., "critical", "warning", "advisory"
    let createdAt: [Int]?    // Java LocalDateTime: [2025, 11, 18, 14, 30...]
}

extension HealthRecommendation {
    
    // 1. Logic to distinguish Weekly vs Daily based on your 'source' field
    var isWeeklySummary: Bool {
        return source == "weekly_summary"
    }
    
    // 2. Convert Java [Year, Month, Day...] to Swift Date
    var uiDate: Date {
        guard let arr = createdAt, arr.count >= 3 else { return Date() }
        // Java months are 1-12, Swift DateComponents expects 1-12 too, usually safe.
        let components = DateComponents(
            year: arr[0],
            month: arr[1],
            day: arr[2],
            hour: arr.count > 3 ? arr[3] : 0,
            minute: arr.count > 4 ? arr[4] : 0
        )
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // 3. Formatted Date String (e.g., "18 Nov, 14:30")
    var uiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: uiDate)
    }
    
    // 4. Color based on 'severity' field from backend
    var uiColor: UIColor {
        switch severity?.lowercased() {
        case "critical", "high": return .systemRed
        case "warning", "medium": return .systemOrange
        case "advisory", "low": return UIColor(hex: "#362E83") // Your brand blue
        default: return .systemGray
        }
    }
    
    // 5. Icon based on 'severity' or 'source'
    var uiIconName: String {
        if isWeeklySummary { return "calendar.badge.clock" }
        
        switch severity?.lowercased() {
        case "critical": return "exclamationmark.triangle.fill"
        case "warning": return "stethoscope"
        default: return "bubble.left.and.bubble.right.fill" // Advisory
        }
    }
    
    // 6. Title based on 'source'
    var uiTitle: String {
        if isWeeklySummary { return "Weekly Report" }
        if let src = source {
            // Make "ml_model" look nicer -> "ML Insight"
            let formatted = src.replacingOccurrences(of: "_", with: " ").capitalized
            return "\(formatted) Tip"
        }
        return "Health Tip"
    }
    
    // MARK: - Mock Data (Matching your Backend Structure)
    static func getMockData() -> [HealthRecommendation] {
        return [
            HealthRecommendation(recId: 101, recommendationText: "High fatigue risk detected. Consider a rest day.", source: "ml_model", severity: "critical", createdAt: [2025, 11, 18, 10, 0]),
            HealthRecommendation(recId: 102, recommendationText: "Two consecutive days of low activity.", source: "rules", severity: "advisory", createdAt: [2025, 11, 18, 09, 30]),
            HealthRecommendation(recId: 103, recommendationText: "This week was moderately demanding. Days with elevated fatigue risk: 3 out of 7.", source: "weekly_summary", severity: "warning", createdAt: [2025, 11, 17, 20, 0])
        ]
    }
}
