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
        
        // 👇 1. ПОДПИСКА НА ОБНОВЛЕНИЕ (Как в Dashboard)
        // Это критически важно, чтобы экран обновился после фоновой работы ML
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAutoRefresh),
            name: NSNotification.Name("HistoryDataSynced"),
            object: nil
        )
        
        fetchData()
    }
    
    // 👇 2. Обновляем данные при каждом входе на вкладку
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupNavigation() {
        title = "Insights"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupDelegates() {
        mainView.tableView.delegate = self
        mainView.tableView.dataSource = self
        
        // Pull-to-Refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        mainView.tableView.refreshControl = refreshControl
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        fetchData()
    }
    
    // 👇 3. АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ (С задержкой для БД)
    @objc private func handleAutoRefresh() {
        print("🔄 Recommendations received sync signal. Refreshing...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.fetchData()
        }
    }
    
    // MARK: - Data Fetching
    
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
                    // 1. Фильтруем по юзеру
                    let myRecs = list.filter { $0.userId == userId }
                    
                    // 👇 4. УБИРАЕМ ДУБЛИКАТЫ (Это то, что я добавил в прошлый раз и что нужно вернуть)
                    let uniqueRecs = self.removeDuplicates(from: myRecs)
                    
                    // 2. Сортируем (новые сверху)
                    let sortedData = uniqueRecs.sorted { $0.uiDate > $1.uiDate }
                    
                    // 3. Разделяем на категории
                    self.weeklyRecommendations = sortedData.filter { $0.isWeeklySummary }
                    self.dailyRecommendations = sortedData.filter { !$0.isWeeklySummary }
                    
                    print("Loaded \(myRecs.count) recommendations (Unique: \(uniqueRecs.count))")
                    
                    // 4. Обновляем экран
                    self.mainView.toggleEmptyState(isEmpty: uniqueRecs.isEmpty)
                    self.mainView.tableView.reloadData()
                    
                case .failure(let error):
                    print("Failed to load recommendations: \(error.localizedDescription)")
                    // Если ошибка, показываем пустой экран только если данных нет совсем
                    if self.weeklyRecommendations.isEmpty && self.dailyRecommendations.isEmpty {
                        self.mainView.toggleEmptyState(isEmpty: true)
                    }
                }
            }
        }
    }
    
    private func removeDuplicates(from list: [HealthRecommendation]) -> [HealthRecommendation] {
        var seen = Set<String>()
        var unique: [HealthRecommendation] = []
        
        let sortedById = list.sorted { $0.recId > $1.recId }
        
        for rec in sortedById {
            let dateKey = DateFormatters.yyyyMMdd.string(from: rec.uiDate)
            let uniqueKey = "\(dateKey)_\(rec.source ?? "unknown")"
            
            if !seen.contains(uniqueKey) {
                seen.insert(uniqueKey)
                unique.append(rec)
            }
        }
        return unique
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
