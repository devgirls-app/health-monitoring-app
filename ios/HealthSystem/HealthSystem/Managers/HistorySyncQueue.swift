//
//  HistorySyncQueue.swift
//  HealthSystem
//
//  Created by Elina Karimova on 20/11/25.
//

import Foundation
import UIKit

final class HistorySyncQueue {
    
    private let userId: Int?
    private let networkManager = NetworkManager.shared
    
    // Пауза между запросами отправки (чтобы не банил Cloudflare)
    private let delayBetweenRequests = 0.5
    
    // 🚨 НОВОЕ: Пауза для Kafka (чтобы сервер успел сохранить данные перед отчетом)
    private let kafkaProcessingBuffer = 30.0
    
    init(userId: Int?) {
        self.userId = userId
    }
    
    public func startSequentialSync(days: Int, completion: @escaping () -> Void) {
        guard let userId = self.userId, AuthManager.shared.isAuthenticated else {
            completion()
            return
        }
        
        let calendar = Calendar.current
        var daysToSync: [Date] = []
        
        for i in 1...days {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: Date().startOfDay) {
                daysToSync.append(pastDate)
            }
        }
        
        print("Starting background history sync (Range: \(daysToSync.count) days).")
        syncNextDay(daysToSync: daysToSync, index: 0, userId: userId, finalCompletion: completion)
    }
    
    private func syncNextDay(daysToSync: [Date], index: Int, userId: Int, finalCompletion: @escaping () -> Void) {
        
        // УСЛОВИЕ ВЫХОДА (ВСЕ ДНИ ОТПРАВЛЕНЫ)
        guard AuthManager.shared.isAuthenticated, index < daysToSync.count else {
            print("✅ History upload complete.")
            print("⏳ Waiting \(kafkaProcessingBuffer)s for Kafka/DB to process data...")
            
            // 🚨 ИСПРАВЛЕНИЕ: ЖДЕМ, ПОКА KAFKA СОХРАНИТ ДАННЫЕ
            DispatchQueue.global().asyncAfter(deadline: .now() + kafkaProcessingBuffer) {
                
                // Только теперь просим отчет
                self.triggerWeeklySummary(userId: userId) {
                    print("🏁 All sync tasks done. Signaling Dashboard.")
                    finalCompletion()
                }
            }
            return
        }
        
        let pastDate = daysToSync[index]
        let dateString = DateFormatters.yyyyMMdd.string(from: pastDate)
        
        HealthKitManager.shared.fetchSnapshot(for: pastDate) { [weak self] snapshot in
            guard let self = self else { return }
            
            func proceedToNext() {
                DispatchQueue.global().asyncAfter(deadline: .now() + self.delayBetweenRequests) {
                    self.syncNextDay(daysToSync: daysToSync, index: index + 1, userId: userId, finalCompletion: finalCompletion)
                }
            }
            
            guard let snapshot = snapshot else {
                proceedToNext()
                return
            }
            
            if (snapshot.steps ?? 0) > 10 || (snapshot.sleepHours ?? 0) > 0.5 {
                let dto = snapshot.toDTO(userId: userId)
                
                self.networkManager.postHealthData(dto) { [weak self] result in
                    if case .success = result {
                        // print("History sent: \(dateString)")
                      
                        self?.triggerAggregationForHistory(userId: userId, date: dateString)
                    }
                    proceedToNext()
                }
            } else {
                proceedToNext()
            }
        }
    }
    
    private func triggerAggregationForHistory(userId: Int, date: String) {
        networkManager.runAggregate(userId: userId, date: date) { _ in }
    }
    
    private func triggerWeeklySummary(userId: Int, completion: @escaping () -> Void) {
        let calendar = Calendar.current
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday == 1) ? 0 : (weekday - 1)
        
        guard let weekEnd = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            completion()
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekEndString = formatter.string(from: weekEnd)
        
        print("⚡️ Triggering Weekly Summary for: \(weekEndString)")
        
        networkManager.debugTriggerWeeklySummary(userId: userId, date: weekEndString) { result in
            if case .success = result {
                print("✅ Weekly Summary GENERATED with fresh data!")
            } else {
                print("⚠️ Weekly Summary request finished: \(result)")
            }
            // Важно: возвращаем управление в DashboardController
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
