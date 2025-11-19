//
//  HealthKitManager.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 22/10/25.
//

import HealthKit

final class HealthKitManager {
    
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    // MARK: - Request Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard
            let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
            let hr = HKObjectType.quantityType(forIdentifier: .heartRate),
            let calories = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let weight = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)
        else {
            completion(false, nil)
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            steps, hr, calories, distance, sleep, height, weight,
            biologicalSex, dateOfBirth
        ]
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success, error)
        }
    }
    
    // MARK: - Fetch Today Snapshot (Для Дашборда: Сегодня)
    func fetchTodaySnapshot(manualHR: Int?, completion: @escaping (HealthSnapshot?) -> Void) {
        
        let group = DispatchGroup()
        
        var steps: Int?
        var calories: Double?
        var distance: Double?
        var sleepHours: Double?
        var hrAvg: Int?
        var userHeight: Double?
        var userWeight: Double?
        
        var userAge: Int?
        var userGender: String?
        
        fetchUserCharacteristics { age, gender in
            userAge = age
            userGender = gender
        }
        
        let now = Date()
        
        group.enter()
        fetchSteps(for: now) { value, _ in
            if let v = value { steps = Int(v) }
            group.leave()
        }
        
        group.enter()
        fetchCalories(for: now) { value in
            calories = value
            group.leave()
        }
        
        group.enter()
        fetchDistance(for: now) { value in
            distance = value
            group.leave()
        }
        
        group.enter()
        fetchSleepHours(for: now) { value in
            sleepHours = value
            group.leave()
        }
        
        group.enter()
        fetchHeartRate(for: now) { samples, _ in
            if let samples = samples, !samples.isEmpty {
                let avg = self.averageHeartRate(from: samples)
                hrAvg = Int(avg)
            }
            group.leave()
        }
        
        group.enter()
        fetchLatestSample(for: .height, unit: .meter()) { value in
            if let val = value {
                userHeight = val * 100
            }
            group.leave()
        }

        group.enter()
        fetchLatestSample(for: .bodyMass, unit: .gramUnit(with: .kilo)) { value in
            userWeight = value
            group.leave()
        }
        
        group.notify(queue: .main) {
            let formatter = ISO8601DateFormatter()
            let isoTimestamp = formatter.string(from: now)
            
            let snapshot = HealthSnapshot(
                steps: steps,
                averageHeartRate: hrAvg,
                calories: calories,
                sleepHours: sleepHours,
                distance: distance,
                manualHeartRate: manualHR,
                timestamp: isoTimestamp,
                age: userAge,
                gender: userGender,
                height: userHeight,
                weight: userWeight
            )
            
            completion(snapshot)
        }
    }
    
    // MARK: - Fetch History Snapshot (Для заполнения дырок: Прошлые дни)
    func fetchSnapshot(for date: Date, completion: @escaping (HealthSnapshot?) -> Void) {
        let group = DispatchGroup()
        
        var steps: Int?
        var calories: Double?
        var sleepHours: Double?
        
        group.enter()
        fetchSteps(for: date) { value, _ in
            if let v = value { steps = Int(v) }
            group.leave()
        }
        
        group.enter()
        fetchCalories(for: date) { value in
            calories = value
            group.leave()
        }
        
        group.enter()
        fetchSleepHours(for: date) { value in
            sleepHours = value
            group.leave()
        }
        
        group.notify(queue: .main) {
            let formatter = ISO8601DateFormatter()
            let isoTimestamp = formatter.string(from: date)
            
            let snapshot = HealthSnapshot(
                steps: steps,
                averageHeartRate: nil,
                calories: calories,
                sleepHours: sleepHours,
                distance: nil,
                manualHeartRate: nil,
                timestamp: isoTimestamp,
                age: nil,
                gender: nil,
                height: nil,
                weight: nil
            )
            completion(snapshot)
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func fetchLatestSample(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            completion(sample.quantity.doubleValue(for: unit))
        }
        healthStore.execute(query)
    }
    
    func fetchSteps(for date: Date, completion: @escaping (Double?, Error?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { completion(nil, nil); return }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        // Конец дня = начало следующего дня
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { completion(nil, nil); return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let sum = result?.sumQuantity() else { completion(nil, error); return }
            completion(sum.doubleValue(for: .count()), nil)
        }
        healthStore.execute(query)
    }

    func fetchCalories(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { completion(nil); return }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { completion(nil); return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie())
            completion(value)
        }
        healthStore.execute(query)
    }
    
    func fetchDistance(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { completion(nil); return }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { completion(nil); return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: .meter())
            completion(value)
        }
        healthStore.execute(query)
    }
    
    func fetchSleepHours(for date: Date, completion: @escaping (Double?) -> Void) {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { completion(nil); return }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { completion(nil); return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { completion(nil); return }
            var total = 0.0
            
            for item in samples {
                if item.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                    item.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    item.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    item.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    
                    let sampleStart = max(item.startDate, start)
                    let sampleEnd = min(item.endDate, end)
                    
                    if sampleEnd > sampleStart {
                        total += sampleEnd.timeIntervalSince(sampleStart)
                    }
                }
            }
            completion(total / 3600.0)
        }
        healthStore.execute(query)
    }
    
    func fetchHeartRate(for date: Date, completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { completion(nil, nil); return }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { completion(nil, nil); return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            completion(samples as? [HKQuantitySample], error)
        }
        healthStore.execute(query)
    }
    
    func averageHeartRate(from samples: [HKQuantitySample]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
        return sum / Double(samples.count)
    }
    
    func fetchUserCharacteristics(completion: @escaping (_ age: Int?, _ gender: String?) -> Void) {
        var age: Int?
        var gender: String?
        do {
            let birthdayComponents = try healthStore.dateOfBirthComponents()
            if let birthday = Calendar.current.date(from: birthdayComponents) {
                let ageComponents = Calendar.current.dateComponents([.year], from: birthday, to: Date())
                age = ageComponents.year
            }
        } catch { print("Failed to fetch DoB: \(error.localizedDescription)") }
        
        do {
            let biologicalSexObject = try healthStore.biologicalSex()
            switch biologicalSexObject.biologicalSex {
            case .female: gender = "female"
            case .male:   gender = "male"
            case .other:  gender = "other"
            default:      gender = "notSet"
            }
        } catch { print("Failed to fetch Sex: \(error.localizedDescription)") }
        completion(age, gender)
    }
}
