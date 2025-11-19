//
//  RecommendationsController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import UIKit

final class RecommendationsController: UIViewController {
    
    // MARK: - Properties
    
    private let mainView = RecommendationsView()
    private var currentUserId: Int? {
        return AuthManager.shared.getUserId()
    }
    
    private var weeklyRecommendations: [HealthRecommendation] = []
    private var dailyRecommendations: [HealthRecommendation] = []
    
    // MARK: - Lifecycle
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupDelegates()
        
        fetchData()
    }
    
    // MARK: - Setup
    
    private func setupNavigation() {
        title = "Recommendations"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupDelegates() {
        mainView.tableView.delegate = self
        mainView.tableView.dataSource = self
        
        // Added Pull-to-Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        mainView.tableView.refreshControl = refreshControl
    }
    
    @objc private func handleRefresh() {
        fetchData()
    }
    
    // MARK: - Data Fetching (REAL API)
    
    private func fetchData() {
        guard let userId = currentUserId else {
            print("No User ID found")
            mainView.tableView.refreshControl?.endRefreshing()
            return
        }
        
        NetworkManager.shared.fetchRecommendations { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.mainView.tableView.refreshControl?.endRefreshing()
                
                switch result {
                case .success(let list):
                    // 1. Filter
                    let myRecs = list.filter { $0.userId == userId }
                    
                    // 2. Sort
                    let sortedData = myRecs.sorted { $0.uiDate > $1.uiDate }
                    
                    // 3. Divide to categories (using logic from HealthModels.swift)
                    self.weeklyRecommendations = sortedData.filter { $0.isWeeklySummary }
                    self.dailyRecommendations = sortedData.filter { !$0.isWeeklySummary }
                    
                    print("Loaded \(myRecs.count) recommendations for UI")
                    
                    // 4. Refresh screen
                    self.mainView.toggleEmptyState(isEmpty: myRecs.isEmpty)
                    self.mainView.tableView.reloadData()
                    
                case .failure(let error):
                    print("Failed to load recommendations: \(error.localizedDescription)")
                    self.mainView.toggleEmptyState(isEmpty: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension RecommendationsController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && !weeklyRecommendations.isEmpty {
            return "Weekly Reports"
        } else if section == 1 && !dailyRecommendations.isEmpty {
            return "Daily Insights"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return weeklyRecommendations.count
        } else {
            return dailyRecommendations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RecommendationCell.identifier, for: indexPath) as? RecommendationCell else {
            return UITableViewCell()
        }
        
        let item: HealthRecommendation
        if indexPath.section == 0 {
            item = weeklyRecommendations[indexPath.row]
        } else {
            item = dailyRecommendations[indexPath.row]
        }
        
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
