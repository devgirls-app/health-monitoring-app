//
//  HealthModels.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import Foundation
import UIKit

extension HealthRecommendation {
    
    var isWeeklySummary: Bool {
        return source == "weekly_summary"
    }
    
    var uiDate: Date {
        guard let arr = createdAt, arr.count >= 3 else { return Date() }
        let components = DateComponents(
            year: arr[0],
            month: arr[1],
            day: arr[2],
            hour: arr.count > 3 ? arr[3] : 0,
            minute: arr.count > 4 ? arr[4] : 0,
            second: arr.count > 5 ? arr[5] : 0
        )
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var uiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: uiDate)
    }
    
    var uiColor: UIColor {
        switch severity?.lowercased() {
        case "critical", "high": return .systemRed
        case "warning", "medium": return .systemOrange
        case "advisory", "low": return UIColor(hex: "#362E83")
        default: return .systemGray
        }
    }
    
    var uiIconName: String {
        if isWeeklySummary { return "calendar.badge.clock" }
        
        switch severity?.lowercased() {
        case "critical": return "exclamationmark.triangle.fill"
        case "warning": return "stethoscope"
        default: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var uiTitle: String {
        if isWeeklySummary { return "Weekly Report" }
        if let src = source {
            let formatted = src.replacingOccurrences(of: "_", with: " ").capitalized
            return "\(formatted) Tip"
        }
        return "Health Tip"
    }
    
    // MARK: - Mock Data 
    static func getMockData() -> [HealthRecommendation] {
        return [
            HealthRecommendation(recId: 101, recommendationText: "High fatigue risk detected. Consider a rest day.", source: "ml_model", severity: "critical", createdAt: [2025, 11, 18, 10, 0], userId: 1),
            HealthRecommendation(recId: 102, recommendationText: "Two consecutive days of low activity.", source: "rules", severity: "advisory", createdAt: [2025, 11, 18, 09, 30], userId: 1),
            HealthRecommendation(recId: 103, recommendationText: "This week was moderately demanding. Days with elevated fatigue risk: 3 out of 7.", source: "weekly_summary", severity: "warning", createdAt: [2025, 11, 17, 20, 0], userId: 1)
        ]
    }
}
