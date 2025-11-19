//
//  DashboardViewController.swift
//  HealthSystem
//

import UIKit

// MARK: - Date Helpers
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

final class DashboardController: UIViewController {

    // MARK: - Inputs
    private var currentUserId: Int? {
        return AuthManager.shared.getUserId()
    }
    
    // MARK: - State
    private var userProfile: UserProfile?
    
    // MARK: - View
    private let mainView = DashboardView()
    
    override func loadView() {
        self.view = mainView
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        
        // 1. Current day (UI + Sync)
        requestHealthKitAndThenRefreshDashboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupActions() {
        mainView.moreButton.addTarget(self, action: #selector(handleMoreTap), for: .touchUpInside)
    }
    
    @objc private func handleMoreTap() {
        self.tabBarController?.selectedIndex = 2
    }
    
    // MARK: - Calculation Helper
    private func calculateDaysToSync(calendar: Calendar) -> [Date] {
        let today = Date()
        var daysToSync: [Date] = []
        var mutableCalendar = calendar
        
        mutableCalendar.firstWeekday = 2

        guard let startOfCurrentWeek = mutableCalendar.date(from: mutableCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        guard let startOfPreviousWeek = mutableCalendar.date(byAdding: .day, value: -7, to: startOfCurrentWeek) else {
            return []
        }

        var currentDate = today.startOfDay
        let targetBoundary = startOfPreviousWeek.startOfDay

        while currentDate >= targetBoundary {
            daysToSync.append(currentDate)
            guard let previousDay = mutableCalendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay.startOfDay
        }
        
        return daysToSync
    }

    // MARK: - History Sync (Sequential Sync)
    
    private func syncMissingDaysSequentially() {
        guard AuthManager.shared.isAuthenticated else {
            print("Auth check failed. Skipping history sync.")
            return
        }
        guard currentUserId != nil else { return }
        
        let daysToSync = calculateDaysToSync(calendar: Calendar.current)
        print("Starting background history sync (Range: \(daysToSync.count) days).")
        
        syncNextDay(daysToSync: daysToSync, index: 0)
    }

    private func syncNextDay(daysToSync: [Date], index: Int) {
        guard AuthManager.shared.isAuthenticated else {
            print("Token expired mid-sync. Aborting history sync.")
            return
        }
        
        guard index < daysToSync.count else {
            print("History sync complete.")
            
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            
            let daysToSubtract = (weekday == 1) ? 7 : (weekday - 1)

            guard let weekEnd = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let weekEndString = formatter.string(from: weekEnd)

            if let userId = currentUserId {
                 print("⚡️ Forcing Weekly Summary generation...")
                 
                 let baseUrl = NetworkManager.shared.getBaseURLString()
                 print("DEBUG Trigger path: \(baseUrl)/ml-test/weekly-fatigue/\(userId)/\(weekEndString)")
                 
                 NetworkManager.shared.debugTriggerWeeklySummary(userId: userId, date: weekEndString) { result in
                     if case .success = result {
                         print("Weekly Summary GENERATED! Pull to refresh recommendations.")
                     } else {
                         print("Failed to generate summary: \(result)")
                     }
                 }
            }
            return
        }

        guard let userId = currentUserId else { return }

        let pastDate = daysToSync[index]

        HealthKitManager.shared.fetchSnapshot(for: pastDate) { [weak self] snapshot in
            guard let snapshot = snapshot, let self = self else {
                self?.syncNextDay(daysToSync: daysToSync, index: index + 1)
                return
            }
            
            // Пропускаем сегодняшний день (daysToSync[0]), так как он уже был отправлен в fetchDataAndSync.
            if index > 0 && (snapshot.steps ?? 0) > 10 {
                let timestampString = DateFormatters.localNoZ.string(from: pastDate)
                
                let dto = HealthDataDTO(
                    userId: userId,
                    timestamp: timestampString,
                    heartRate: 0,
                    steps: snapshot.steps,
                    calories: snapshot.calories,
                    sleepHours: snapshot.sleepHours,
                    distance: snapshot.distance,
                    age: snapshot.age,
                    gender: snapshot.gender,
                    source: "healthkit_history",
                    height: snapshot.height,
                    weight: snapshot.weight
                )
                
                NetworkManager.shared.postHealthData(dto) { [weak self] result in
                    let logDate = DateFormatters.yyyyMMdd.string(from: pastDate)
                    
                    if case .success = result {
                        print("History synced for: \(logDate)")
                    } else {
                        print("Failed to sync history for: \(logDate) (Failure: \(result))")
                    }
                    
                    self?.syncNextDay(daysToSync: daysToSync, index: index + 1)
                }
            } else {
                self.syncNextDay(daysToSync: daysToSync, index: index + 1)
            }
        }
    }
    
    // MARK: - HealthKit & Data Flow (Current Day)
    
    private func requestHealthKitAndThenRefreshDashboard() {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                print("HealthKit access granted")
                self.fetchDataAndSync()
            } else {
                print("HealthKit access denied:", error?.localizedDescription ?? "unknown")
                self.syncProfileAndFetchUI(snapshot: nil)
            }
        }
    }
    
    private func fetchDataAndSync() {
        let manualHR: Int? = nil
        
        HealthKitManager.shared.fetchTodaySnapshot(manualHR: manualHR) { [weak self] (snapshot: HealthSnapshot?) in
            guard let self = self else { return }
            
            guard let snapshot = snapshot else {
                print("Failed to build snapshot")
                self.syncProfileAndFetchUI(snapshot: nil)
                return
            }
            
            DispatchQueue.main.async {
                print("UI Updated with LOCAL HealthKit snapshot")
                self.updateMetricsUI(with: snapshot)
            }
            
            let dto = snapshot.toDTO(userId: self.currentUserId ?? 0)
            
            // ОТПРАВКА В KAFKA
            NetworkManager.shared.postHealthData(dto) { result in
                // ЖЕСТКАЯ ПРОВЕРКА УСПЕХА!
                if case .success = result {
                    print("Today's snapshot sent")
                    self.syncProfileAndFetchUI(snapshot: snapshot)
                } else {
                    print("Failed to send snapshot (403 or other failure). Stopping sync chain.")
                    self.fetchServerDataOnly()
                }
            }
        }
    }
    
    // СИНХРОНИЗАЦИЯ ПРОФИЛЯ и ЗАПУСК ФОНОВОЙ РАБОТЫ
    private func syncProfileAndFetchUI(snapshot: HealthSnapshot?) {
        guard AuthManager.shared.isAuthenticated else {
            print("Token expired before syncProfileAndFetchUI. Aborting.")
            self.fetchServerDataOnly()
            return
        }
        guard let userId = self.currentUserId else {
            self.fetchServerDataOnly()
            return
        }

        NetworkManager.shared.syncUserProfile(
            userId: userId,
            age: snapshot?.age,
            weight: snapshot?.weight,
            height: snapshot?.height,
            gender: snapshot?.gender
        ) { [weak self] result in
            
            var success = false
            if case .success = result {
                success = true
                print("User profile synced.")
            } else {
                success = false
                print("Failed to sync profile.")
            }
            
            // 1. Обновляем UI после синхронизации профиля
            self?.fetchServerDataOnly()
            
            // 2. ЗАПУСКАЕМ СИНХРОНИЗАЦИЮ ИСТОРИИ ТОЛЬКО ПОСЛЕ УСПЕШНОГО ОБНОВЛЕНИЯ ПРОФИЛЯ.
            if success {
                 self?.syncMissingDaysSequentially()
            } else {
                 print("Skipping history sync due to profile sync failure.")
            }
        }
    }
    
    // MARK: - Fetching Server Data
    
    private func fetchServerDataOnly() {
        guard let userId = currentUserId else { return }
        
        let group = DispatchGroup()
        
        // 1. Профиль
        group.enter()
        NetworkManager.shared.fetchUserProfile(userId: userId) { [weak self] result in
            defer { group.leave() }
            if case .success(let profile) = result {
                self?.userProfile = profile
            }
        }
        
        // 2. Рекомендации отдельно
        var fetchedRecs: [HealthRecommendation] = []
        group.enter()
        NetworkManager.shared.fetchRecommendations { result in
            defer { group.leave() }
            if case .success(let list) = result {
                fetchedRecs = list.filter { $0.userId == userId }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if let profile = self.userProfile {
                self.userProfile = UserProfile(
                    userId: profile.userId,
                    name: profile.name,
                    age: profile.age,
                    gender: profile.gender,
                    height: profile.height,
                    weight: profile.weight,
                    recommendations: fetchedRecs
                )
            }
            
            print("User Profile & Recommendations loaded")
            self.updateRecommendationUI()
        }
    }
    
    // MARK: - UI Updates
    
    private func updateMetricsUI(with localSnapshot: HealthSnapshot) {
        mainView.updateStats(
            hr: localSnapshot.averageHeartRate ?? 0,
            steps: localSnapshot.steps ?? 0,
            calories: Int((localSnapshot.calories ?? 0).rounded()),
            sleep: localSnapshot.sleepHours ?? 0
        )
    }
    
    private func updateRecommendationUI() {
        mainView.updateGreeting(name: userProfile?.name)
        
        guard let recs = userProfile?.recommendations, !recs.isEmpty else {
            mainView.updateRecommendation(text: "No recommendations yet. Keep tracking! 🏃‍♀️")
            return
        }
        
        if let latest = recs.sorted(by: { $0.uiDate > $1.uiDate }).first {
            mainView.updateRecommendation(text: latest.recommendationText)
            print("Showing Rec: \(latest.uiTitle)")
        }
    }
}
