//
//  RecommendationCell.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import UIKit
import SnapKit

class RecommendationCell: UITableViewCell {
    
    static let identifier = "RecommendationCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubviews(iconImageView, titleLabel, dateLabel, messageLabel)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalTo(dateLabel.snp.leading).offset(-8)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView)
            make.trailing.equalToSuperview().offset(-12)
            make.width.lessThanOrEqualTo(120)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with model: HealthRecommendation) {
        // Using the UI Extension properties we created
        titleLabel.text = model.uiTitle
        messageLabel.text = model.recommendationText
        dateLabel.text = model.uiDateString
        
        iconImageView.image = UIImage(systemName: model.uiIconName)
        iconImageView.tintColor = model.uiColor
        titleLabel.textColor = model.uiColor
    }
}
