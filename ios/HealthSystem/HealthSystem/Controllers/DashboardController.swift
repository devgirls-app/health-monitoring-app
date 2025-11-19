//
//  DashboardViewController.swift
//  HealthSystem
//

import UIKit

final class DashboardController: UIViewController {
    
    // MARK: - Inputs
    private var currentUserId: Int? {
        return AuthManager.shared.getUserId()
    }
    
    // MARK: - State
    private var userProfile: UserProfile?
    private var dailySummary: DailySummary?
    
    // MARK: - View
    private let mainView = DashboardView()
    
    override func loadView() {
        self.view = mainView
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        requestHealthKitAndThenRefreshDashboard()
    }
    
    private func setupActions() {
        mainView.moreButton.addTarget(self, action: #selector(handleMoreTap), for: .touchUpInside)
    }
    
    @objc private func handleMoreTap() {
        print("More button tapped")
    }
    
    // MARK: - HealthKit & Data Flow
    
    private func requestHealthKitAndThenRefreshDashboard() {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                print("HealthKit access granted")
                self.fetchDataAndSync()
            } else {
                print("HealthKit access denied:", error?.localizedDescription ?? "unknown")
                self.fetchDashboardData()
            }
        }
    }
    
    private func fetchDataAndSync() {
        let manualHR: Int? = nil
        
        HealthKitManager.shared.fetchTodaySnapshot(manualHR: manualHR) { [weak self] (snapshot: HealthSnapshot?) in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Failed to build snapshot")
                self.fetchDashboardData()
                return
            }
            
            DispatchQueue.main.async {
                print("Updating UI with LOCAL snapshot")
                self.updateUI(with: snapshot)
            }
            
            let dto = snapshot.toDTO(userId: self.currentUserId ?? 0)
            
            NetworkManager.shared.postHealthData(dto) { result in
                switch result {
                case .success:
                    print("Health snapshot sent")
                case .failure(let error):
                    print("Failed to send snapshot:", error)
                }
                
                self.syncProfileAndAggregate(snapshot: snapshot)
            }
        }
    }
    
    private func syncProfileAndAggregate(snapshot: HealthSnapshot) {
        guard let userId = self.currentUserId else {
            print("⚠️ User ID not found, skipping sync")
            return
        }

        print("🔄 Syncing profile for User ID: \(userId)")
        
        NetworkManager.shared.syncUserProfile(
            userId: userId,
            age: snapshot.age,
            weight: snapshot.weight,
            height: snapshot.height,
            gender: snapshot.gender
        ) { result in
            switch result {
            case .success:
                print("User profile synced successfully!")
            case .failure(let error):
                print("Failed to sync profile: \(error)")
            }
            
            self.runAggregationAndFetchDashboard()
        }
    }
    
    private func runAggregationAndFetchDashboard() {
        guard let userId = currentUserId else { return }
        
        let today = Date()
        let todayString = DateFormatters.yyyyMMdd.string(from: today)
        
        NetworkManager.shared.runAggregate(userId: userId, date: todayString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let summary):
                print("Aggregation done:", summary)
                self.fetchDashboardData()
            case .failure(let error):
                print("Aggregation error:", error)
                self.fetchDashboardData()
            }
        }
    }
    
    // MARK: - Fetching Data for UI
    private func fetchDashboardData() {
        guard let userId = currentUserId else { return }

        DispatchQueue.main.async {
            self.mainView.setLoading(true)
        }
        
        let group = DispatchGroup()
        var fetchError: Error?
        
        group.enter()
        NetworkManager.shared.fetchUserProfile(userId: userId) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let profile):
                self?.userProfile = profile
            case .failure(let error):
                fetchError = error
            }
        }
        
        let today = Date()
        let todayString = DateFormatters.yyyyMMdd.string(from: today)
        
        group.enter()
        NetworkManager.shared.runAggregate(userId: userId, date: todayString) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let summary):
                self?.dailySummary = summary
            case .failure(let error):
                fetchError = error
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.mainView.setLoading(false)
            
            if let err = fetchError {
                print("Error fetching dashboard data:", err.localizedDescription)
                return
            }
            
            print("Dashboard data loaded.")
            self.updateUIFromNetworkData()
        }
    }
    
    // MARK: - UI Updates Handlers
    private func updateUI(with localSnapshot: HealthSnapshot) {
        mainView.updateStats(
            hr: localSnapshot.averageHeartRate ?? 0,
            steps: localSnapshot.steps ?? 0,
            calories: Int((localSnapshot.calories ?? 0).rounded()),
            sleep: localSnapshot.sleepHours ?? 0
        )
    }
    
    private func updateUIFromNetworkData() {
        mainView.updateGreeting(name: userProfile?.name)
        
        let recText = userProfile?.recommendations?.first?.recommendationText
        mainView.updateRecommendation(text: recText)
        
//        let hr  = Int((dailySummary?.hrMean ?? 0).rounded())
//        let st  = dailySummary?.stepsTotal ?? 0
//        let cal = Int((dailySummary?.caloriesTotal ?? 0).rounded())
//        let sl  = dailySummary?.sleepHoursTotal ?? 0
//        
//        mainView.updateStats(hr: hr, steps: st, calories: cal, sleep: sl)
    }
}
