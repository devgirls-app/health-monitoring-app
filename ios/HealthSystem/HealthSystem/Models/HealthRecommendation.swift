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
    
    // Форматированная строка даты
    var uiDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: uiDate)
    }
    
    // Цвет для UI, основанный на severity
    var uiColor: UIColor {
        switch severity?.lowercased() {
        case "critical", "high": return .systemRed
        case "warning", "medium": return .systemOrange
        case "advisory", "low": return UIColor(hex: "#362E83") // Ваш бренд-синий
        default: return .systemGray
        }
    }
    
    // Иконка для UI, основанная на типе рекомендации
    var uiIconName: String {
        if isWeeklySummary { return "calendar.badge.clock" }
        
        switch severity?.lowercased() {
        case "critical": return "exclamationmark.triangle.fill"
        case "warning": return "stethoscope"
        default: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    // Заголовок для UI
    var uiTitle: String {
        if isWeeklySummary { return "Weekly Report" }
        if let src = source {
            let formatted = src.replacingOccurrences(of: "_", with: " ").capitalized
            return "\(formatted) Tip"
        }
        return "Health Tip"
    }
}
