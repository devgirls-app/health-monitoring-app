//
//  HealthDataDTO.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 22/10/25.
//

import Foundation

struct HealthDataDTO: Codable {
    let userId: Int
    let timestamp: String
    let heartRate: Int?
    let steps: Int?
    let calories: Double?
    let sleepHours: Double?
    let distance: Double?
    let age: Int?
    let gender: String?        
    let source: String?
}
