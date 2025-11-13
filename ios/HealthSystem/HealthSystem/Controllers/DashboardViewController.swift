//
//  DashboardViewController.swift
//  HealthSystem
//

import UIKit
import SnapKit

private enum DateFormatters {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let localNoZ: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale   = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()
}

final class DashboardViewController: UIViewController {

    // MARK: - Inputs
    private let currentUserId: Int = 1

    // MARK: - State
    private var userProfile: UserProfile?
    private var dailySummary: DailySummary?

    // MARK: - UI
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello 👋"
        label.font = .boldSystemFont(ofSize: 28)
        return label
    }()

    private let statusIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 6
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "All health datas are normal"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        return label
    }()

    private lazy var pulseCard    = StatCardView(icon: "❤️", value: "—", label: "Pulse",    color: .systemRed)
    private lazy var stepsCard    = StatCardView(icon: "👣", value: "—", label: "Steps",     color: .systemBlue)
    private lazy var caloriesCard = StatCardView(icon: "🔥", value: "—", label: "Calories",  color: .systemOrange)
    private lazy var sleepCard    = StatCardView(icon: "🌙", value: "—", label: "Sleep",      color: .systemPurple)

    private let recommendationTitle: UILabel = {
        let label = UILabel()
        label.text = "💡 Latest recommendations"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()

    private let recommendationText: UILabel = {
        let label = UILabel()
        label.text = "—"
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        return label
    }()

    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("More", for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()

    private let recommendationContainer = UIView()

    private let activityIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .large)
        i.hidesWhenStopped = true
        return i
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        requestHealthKitAndSend()
        fetchDashboardData()
    }

    // MARK: - HealthKit
    private func requestHealthKitAndSend() {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
            guard let self = self else { return }
            if success {
                print("HealthKit access granted")
                self.collectAndSendToday(userId: self.currentUserId)
            } else {
                print("HealthKit access denied:", error?.localizedDescription ?? "unknown error")
            }
        }
    }

    // MARK: - Networking
    private func fetchDashboardData() {
        activityIndicator.startAnimating()

        let group = DispatchGroup()
        var fetchError: Error?

        group.enter()
        NetworkManager.shared.fetchUserProfile(userId: currentUserId) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let profile):
                self?.userProfile = profile
            case .failure(let error):
                fetchError = error
            }
        }

        // aggregates for today
        let today = Date()
        let todayString = DateFormatters.yyyyMMdd.string(from: today)

        group.enter()
        NetworkManager.shared.runAggregate(userId: currentUserId, date: todayString) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let summary):
                self?.dailySummary = summary
            case .failure(let error):
                fetchError = error
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.activityIndicator.stopAnimating()

            if let err = fetchError {
                print("Error fetching dashboard data:", err.localizedDescription)
                return
            }
            print("Dashboard data loaded.")
            self.updateUI()
        }
    }

    // MARK: - UI Update
    private func updateUI() {
        if let name = userProfile?.name, !name.isEmpty {
            greetingLabel.text = "Hello, \(name) 👋"
        } else {
            greetingLabel.text = "Hello 👋"
        }

        if let rec = userProfile?.recommendations?.first {
            recommendationText.text = rec.recommendationText
        } else {
            recommendationText.text = "No recommendations yet — everything is stable"
        }

        let hr  = dailySummary?.hrMean ?? 0
        let st  = dailySummary?.stepsTotal ?? 0
        let cal = dailySummary?.caloriesTotal ?? 0
        let sl  = dailySummary?.sleepHoursTotal ?? 0

        animateValueChange { [weak self] in
            self?.pulseCard.update(value: "\(Int(hr.rounded())) bpm")
            self?.stepsCard.update(value: "\(st)")
            self?.caloriesCard.update(value: "\(Int(cal.rounded()))")
            self?.sleepCard.update(value: "\(sl) h")
        }
    }

    private func animateValueChange(_ updates: @escaping () -> Void) {
        UIView.animate(withDuration: 0.15, animations: {
            self.pulseCard.alpha = 0.3
            self.stepsCard.alpha = 0.3
            self.caloriesCard.alpha = 0.3
            self.sleepCard.alpha = 0.3
        }, completion: { _ in
            updates()
            UIView.animate(withDuration: 0.2) {
                self.pulseCard.alpha = 1
                self.stepsCard.alpha = 1
                self.caloriesCard.alpha = 1
                self.sleepCard.alpha = 1
            }
        })
    }

    // MARK: - Send Health Data
    func collectAndSendToday(userId: Int) {
        let now = Date()
        HealthKitManager.shared.fetchSteps(for: now) { steps, _ in
            HealthKitManager.shared.fetchHeartRate(for: now) { samples, _ in
                let avgHR = HealthKitManager.shared.averageHeartRate(from: samples ?? [])

                let dto = HealthDataDTO(
                    userId: userId,
                    timestamp: DateFormatters.localNoZ.string(from: now),
                    heartRate: Int(avgHR),
                    steps: steps != nil ? Int(steps!) : nil,
                    calories: nil,
                    sleepHours: nil,
                    source: "iOS"
                )

                NetworkManager.shared.postHealthData(dto) { result in
                    switch result {
                    case .success:
                        print("Health data sent successfully")
                    case .failure(let error):
                        print("Failed to send health data:", error)
                    }
                }
            }
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(greetingLabel)
        view.addSubview(statusIndicator)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)

        greetingLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        statusIndicator.snp.makeConstraints { make in
            make.leading.equalTo(greetingLabel)
            make.top.equalTo(greetingLabel.snp.bottom).offset(8)
            make.size.equalTo(CGSize(width: 12, height: 12))
        }

        statusLabel.snp.makeConstraints { make in
            make.centerY.equalTo(statusIndicator)
            make.leading.equalTo(statusIndicator.snp.trailing).offset(8)
        }

        let topStack = UIStackView(arrangedSubviews: [pulseCard, stepsCard])
        topStack.axis = .horizontal
        topStack.spacing = 16
        topStack.distribution = .fillEqually

        let bottomStack = UIStackView(arrangedSubviews: [caloriesCard, sleepCard])
        bottomStack.axis = .horizontal
        bottomStack.spacing = 16
        bottomStack.distribution = .fillEqually

        let cardsStack = UIStackView(arrangedSubviews: [topStack, bottomStack])
        cardsStack.axis = .vertical
        cardsStack.spacing = 16

        view.addSubview(cardsStack)
        cardsStack.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        // Recommendation
        recommendationContainer.backgroundColor = .white
        recommendationContainer.layer.cornerRadius = 16
        recommendationContainer.layer.shadowColor = UIColor.black.cgColor
        recommendationContainer.layer.shadowOpacity = 0.1
        recommendationContainer.layer.shadowRadius = 4
        recommendationContainer.layer.shadowOffset = CGSize(width: 0, height: 2)

        view.addSubview(recommendationContainer)
        recommendationContainer.snp.makeConstraints { make in
            make.top.equalTo(cardsStack.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        recommendationContainer.addSubview(recommendationTitle)
        recommendationContainer.addSubview(recommendationText)
        recommendationContainer.addSubview(moreButton)

        recommendationTitle.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        recommendationText.snp.makeConstraints { make in
            make.top.equalTo(recommendationTitle.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(recommendationText.snp.bottom).offset(12)
            make.leading.equalTo(recommendationText)
            make.bottom.equalToSuperview().inset(16)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
