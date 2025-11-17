//
//  HealthSnapshot.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 14/11/25.
//

import Foundation

struct HealthSnapshot: Codable {
    let steps: Int?
    let averageHeartRate: Int?
    let calories: Double?
    let sleepHours: Double?
    
    let distance: Double?
    let manualHeartRate: Int?
    let timestamp: String
    
    let age: Int?
    let gender: String?


    func toDTO(userId: Int) -> HealthDataDTO {
        return HealthDataDTO(
            userId: userId,
            timestamp: self.timestamp,
            heartRate: self.averageHeartRate ?? self.manualHeartRate,
            steps: self.steps,
            calories: self.calories,
            sleepHours: self.sleepHours,
            distance: self.distance,
            age: self.age,
            gender: self.gender,
            source: "iOS"
        )
    }
}
