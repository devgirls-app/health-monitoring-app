//
//  ISO8601.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 12/11/25.
//

import Foundation

enum ISO8601 {
    static let withZ: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let noZ: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // without 'Z'
        return f
    }()
}
