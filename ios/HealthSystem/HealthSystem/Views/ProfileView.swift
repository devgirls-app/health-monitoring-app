//
//  ProfileView.swift
//  HealthSystem
//
//  Created by Elina Karimova on 20/11/25.
//

import UIKit
import SnapKit

final class ProfileView: UIView {
    
    // MARK: - UI Components
    
    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .heavy)
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var ageCard = StatCardView(icon: "🎂", value: "—", label: "Age", color: .systemOrange)
    private lazy var heightCard = StatCardView(icon: "📏", value: "—", label: "Height", color: .systemBlue)
    private lazy var weightCard = StatCardView(icon: "⚖️", value: "—", label: "Weight", color: .systemGreen)
    
    private let statsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()
    
    let logoutButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Log Out", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemRed
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.snp.makeConstraints { $0.height.equalTo(55) }
        return btn
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
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
    
    // MARK: - Layout
    private func setupLayout() {
        
        headerStack.addArrangedSubview(nameLabel)
        headerStack.addArrangedSubview(emailLabel)
        
        let statsRow1 = UIStackView(arrangedSubviews: [ageCard, heightCard])
        statsRow1.axis = .horizontal
        statsRow1.spacing = 16
        statsRow1.distribution = .fillEqually
        
        let statsRow2 = UIStackView(arrangedSubviews: [weightCard, UIView()])
        statsRow2.axis = .horizontal
        statsRow2.spacing = 16
        statsRow2.distribution = .fillEqually
        
        statsStack.addArrangedSubview(statsRow1)
        statsStack.addArrangedSubview(statsRow2)
        
        addSubview(headerStack)
        addSubview(statsStack)
        addSubview(logoutButton)
        addSubview(activityIndicator)
        
        headerStack.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(40)
            make.centerX.equalToSuperview()
        }
        
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(250)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(30)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            alpha = 0.6
        } else {
            activityIndicator.stopAnimating()
            alpha = 1.0
        }
    }
    
    func updateUI(with user: UserProfile?) {
        nameLabel.text = "\(user?.name ?? "") \(user?.surname ?? "")"
        emailLabel.text = user?.email
        
        ageCard.update(value: user?.age.map { "\($0) y/o" } ?? "—")
        heightCard.update(value: user?.height.map { "\(Int($0)) cm" } ?? "—")
        weightCard.update(value: user?.weight.map { "\(String(format: "%.0f", $0)) kg" } ?? "—")
    }
}
