//
//  DashboardView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 16/11/25.
//

import UIKit
import SnapKit

final class DashboardView: UIView {
    
    // MARK: - UI Elements
    
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
    private lazy var stepsCard    = StatCardView(icon: "👣", value: "—", label: "Steps",    color: .systemBlue)
    private lazy var caloriesCard = StatCardView(icon: "🔥", value: "—", label: "Calories", color: .systemOrange)
    private lazy var sleepCard    = StatCardView(icon: "🌙", value: "—", label: "Sleep",    color: .systemPurple)
    
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
    
    let moreButton: UIButton = {
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
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGroupedBackground
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    func updateGreeting(name: String?) {
        if let name = name, !name.isEmpty {
            greetingLabel.text = "Hello, \(name) 👋"
        } else {
            greetingLabel.text = "Hello 👋"
        }
    }
    
    func updateRecommendation(text: String?) {
        if let text = text {
            recommendationText.text = text
        } else {
            recommendationText.text = "No recommendations yet — everything is stable"
        }
    }
    
    func updateStats(hr: Int, steps: Int, calories: Int, sleep: Double) {
        animateValueChange {
            self.pulseCard.update(value: "\(hr) bpm")
            self.stepsCard.update(value: "\(steps)")
            self.caloriesCard.update(value: "\(calories)")
            
            // Округляем сон до 1 знака
            let sleepRounded = (sleep * 10).rounded() / 10
            self.sleepCard.update(value: "\(sleepRounded) h")
        }
    }
    
    // MARK: - Private Helpers
    
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
    
    // MARK: - Layout
    
    private func setupLayout() {
        addSubview(greetingLabel)
        addSubview(statusIndicator)
        addSubview(statusLabel)
        addSubview(activityIndicator)
        
        greetingLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(16)
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
        
        addSubview(cardsStack)
        cardsStack.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        recommendationContainer.backgroundColor = .white
        recommendationContainer.layer.cornerRadius = 16
        recommendationContainer.layer.shadowColor = UIColor.black.cgColor
        recommendationContainer.layer.shadowOpacity = 0.1
        recommendationContainer.layer.shadowRadius = 4
        recommendationContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        addSubview(recommendationContainer)
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
