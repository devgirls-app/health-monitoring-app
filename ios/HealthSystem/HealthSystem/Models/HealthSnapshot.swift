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
    let height: Double?
    let weight: Double?


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
            source: "iOS",
            height: self.height,
            weight: self.weight
        )
    }
}
