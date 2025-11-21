//
//  DashboardViewController.swift
//  HealthSystem
//

import UIKit

// MARK: - Date Helpers
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

final class DashboardController: UIViewController {

    // MARK: - Inputs
    private var currentUserId: Int? {
        AuthManager.shared.getUserId()
    }
    
    private let historySyncDays = 14
    
    // MARK: - State
    private var userProfile: UserProfile?
    
    // MARK: - View
    private let mainView = DashboardView()
    private var historySyncQueue: HistorySyncQueue?
    
    override func loadView() {
        self.view = mainView
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        
        self.historySyncQueue = HistorySyncQueue(userId: currentUserId)
        
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
    
    // MARK: - HealthKit & Data Flow
    
    private func requestHealthKitAndThenRefreshDashboard() {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
            guard let self else { return }
            
            if success {
                print("HealthKit access granted")
                self.collectSnapshotAndSend()
            } else {
                print("HealthKit access denied")
                self.syncProfileAndFetchUI(snapshot: nil)
            }
        }
    }
    
    private func collectSnapshotAndSend() {
        let manualHR: Int? = nil
        
        HealthKitManager.shared.fetchTodaySnapshot(manualHR: manualHR) { [weak self] snapshot in
            guard let self else { return }
            
            guard let snapshot = snapshot, let userId = self.currentUserId else {
                self.syncProfileAndFetchUI(snapshot: nil)
                return
            }
            
            DispatchQueue.main.async {
                print("UI Updated with LOCAL HealthKit snapshot")
                self.updateMetricsUI(with: snapshot)
            }
            
            let dto = snapshot.toDTO(userId: userId)
            
            NetworkManager.shared.postHealthData(dto) { result in
                if case .success = result {
                    print("Today's snapshot sent")
                } else {
                    print("Failed to send snapshot")
                }
                
                self.syncProfileAndFetchUI(snapshot: snapshot)
            }
        }
    }
    
    private func syncProfileAndFetchUI(snapshot: HealthSnapshot?) {
        guard let userId = self.currentUserId,
              AuthManager.shared.isAuthenticated else {
            self.fetchServerDataOnly()
            return
        }

        DispatchQueue.main.async {
            self.mainView.updateRecommendation(text: "🔄 Analyzing your data...\nPlease wait.")
        }

        NetworkManager.shared.syncUserProfile(
            userId: userId,
            age: snapshot?.age,
            weight: snapshot?.weight,
            height: snapshot?.height,
            gender: snapshot?.gender
        ) { [weak self] result in
            
            if case .success = result {
                print("User profile synced.")
            }

            // 👉 Сначала агрегируем СЕГОДНЯ
            self?.triggerCurrentAggregation(userId: userId) {

                // 👉 Потом история
                self?.historySyncQueue?.startSequentialSync(days: self?.historySyncDays ?? 14) {

                    print("🔄 History synced. Fetching final ML results...")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.fetchServerDataOnly()
                    }
                }
            }
        }
    }

    // MARK: - Aggregation for Today
    
    private func triggerCurrentAggregation(userId: Int, completion: @escaping () -> Void) {
        let todayString = DateFormatters.yyyyMMdd.string(from: Date())
        
        NetworkManager.shared.runAggregate(userId: userId, date: todayString) { _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    // MARK: - Fetching Server Data
    
    private func fetchServerDataOnly() {
        guard let userId = currentUserId else { return }
        
        DispatchQueue.main.async {
            self.mainView.setLoading(true)
        }
        
        let group = DispatchGroup()
        
        // 1. Профиль
        group.enter()
        NetworkManager.shared.fetchUserProfile(userId: userId) { [weak self] result in
            defer { group.leave() }
            if case .success(let profile) = result {
                self?.userProfile = profile
            }
        }
        
        // 2. Рекомендации
        var fetchedRecs: [HealthRecommendation] = []
        group.enter()
        NetworkManager.shared.fetchRecommendations { result in
            defer { group.leave() }
            if case .success(let list) = result {
                fetchedRecs = list.filter { $0.userId == userId }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            
            self.mainView.setLoading(false)
            
            if let profile = self.userProfile {
                self.userProfile = UserProfile(
                    userId: profile.userId,
                    name: profile.name,
                    surname: profile.surname,
                    email: profile.email,
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
            mainView.updateRecommendation(text: "Tracking your health... 🩺")
            return
        }
        
        let sortedRecs = recs.sorted { (r1, r2) -> Bool in
            func severityWeight(_ s: String?) -> Int {
                switch s?.lowercased() {
                case "critical": return 3
                case "warning": return 2
                default: return 1
                }
            }
            
            let w1 = severityWeight(r1.severity)
            let w2 = severityWeight(r2.severity)
            
            if w1 != w2 {
                return w1 > w2
            } else {
                return r1.uiDate > r2.uiDate
            }
        }
        
        if let bestRec = sortedRecs.first {
            let prefix = bestRec.isWeeklySummary ? "📅 WEEKLY REPORT:\n" : ""
            
            mainView.updateRecommendation(text: prefix + bestRec.recommendationText)
            
            print("Showing Rec on Dashboard: \(bestRec.source ?? "Unknown") | \(bestRec.uiDate)")
        }
    }
}
