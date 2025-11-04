//
//  DashboardViewController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 3/11/25.
//

import UIKit
import SnapKit

final class DashboardViewController: UIViewController {
    
    // MARK: - UI Elements
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.text = "Привет, Арууке 👋"
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
        label.text = "Все показатели в норме"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var pulseCard = StatCardView(icon: "❤️", value: "82 bpm", label: "Пульс", color: .systemRed)
    private lazy var stepsCard = StatCardView(icon: "👣", value: "7 520", label: "Шаги", color: .systemBlue)
    private lazy var caloriesCard = StatCardView(icon: "🔥", value: "2 150", label: "Калории", color: .systemOrange)
    private lazy var sleepCard = StatCardView(icon: "🌙", value: "7 ч", label: "Сон", color: .systemPurple)
    
    private let recommendationTitle: UILabel = {
        let label = UILabel()
        label.text = "💡 Последняя рекомендация"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let recommendationText: UILabel = {
        let label = UILabel()
        label.text = "Ваш пульс выше нормы при низкой активности. Сделайте перерыв и выпейте воды 💧."
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Подробнее", for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        return button
    }()
    
    private let recommendationContainer = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(greetingLabel)
        view.addSubview(statusIndicator)
        view.addSubview(statusLabel)
        
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
        
        // Stack для карточек
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
    }
}

