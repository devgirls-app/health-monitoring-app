//
//  TrendsController.swift
//  HealthSystem
//
//  Created by Elina Karimova on 20/11/25.
//

import UIKit
import SnapKit

final class TrendsController: UIViewController {
    
    // MARK: - Inputs
    private var userId: Int {
        return AuthManager.shared.getUserId() ?? 0
    }
    
    // MARK: - State (Модель данных для View)
    private var trends: [DailySummary] = [] {
        didSet {
            trends.sort { (item1, item2) -> Bool in
                let date1 = (item1.date?[0] ?? 0) * 10000 + (item1.date?[1] ?? 0) * 100 + (item1.date?[2] ?? 0)
                let date2 = (item2.date?[0] ?? 0) * 10000 + (item2.date?[1] ?? 0) * 100 + (item2.date?[2] ?? 0)
                return date1 > date2
            }
            trendsView.tableView.reloadData()
        }
    }
    
    // MARK: - View
    private let trendsView = TrendsView()
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = trendsView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Health Trends"
        
        trendsView.tableView.register(TrendsCell.self, forCellReuseIdentifier: TrendsCell.reuseIdentifier)
        
        trendsView.tableView.dataSource = self
        trendsView.tableView.delegate = self
        
        loadTrends()
    }
    
    // MARK: - Networking
    private func loadTrends() {
        guard userId != 0 else {
            print("Cannot load trends: User ID is missing.")
            return
        }
        
        trendsView.setLoading(true)
        
        NetworkManager.shared.fetchTrends(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.trendsView.setLoading(false)
                
                switch result {
                case .success(let data):
                    self?.trends = data
                    print("Trends loaded successfully: \(data.count) days")
                case .failure(let error):
                    print("Error loading trends: \(error)")
                }
            }
        }
    }
}

// MARK: - TableView Data Source & Delegate
extension TrendsController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TrendsCell.reuseIdentifier, for: indexPath) as? TrendsCell else {
            return UITableViewCell()
        }
        
        let item = trends[indexPath.row]
        cell.configure(with: item)
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Aggregated Data"
    }
}
