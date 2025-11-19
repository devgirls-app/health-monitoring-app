//
//  RecommendationCell.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import UIKit
import SnapKit

final class RecommendationCell: UITableViewCell {

    static let identifier = "RecommendationCellIdentifier"

    private let cardContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white // Белый фон для карточки
        view.layer.cornerRadius = 12 // Скругленные углы
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05 // Очень легкая тень
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        iv.snp.makeConstraints { $0.size.equalTo(24) }
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .right // Дата справа
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Делаем фон ячейки прозрачным, чтобы видеть карточку
        self.backgroundColor = .clear
        self.selectionStyle = .none // Убираем стандартное выделение

        contentView.addSubview(cardContainer)
        cardContainer.addSubview(iconImageView)
        cardContainer.addSubview(stackView)
        cardContainer.addSubview(dateLabel)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(detailLabel)
        
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        // Контейнер карточки должен быть внутри contentView с отступами
        cardContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6) // Небольшой отступ сверху/снизу
            make.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16) // Отступы по бокам
        }

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(12)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            // StackView занимает место между иконкой и датой
            make.trailing.equalTo(dateLabel.snp.leading).offset(-10)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    
    // Этот метод вызывается, когда размер ячейки меняется. Используется для тени.
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обязательно для правильного отображения тени
        cardContainer.layer.shadowPath = UIBezierPath(roundedRect: cardContainer.bounds, cornerRadius: 12).cgPath
    }

    func configure(with recommendation: HealthRecommendation) {
        titleLabel.text = recommendation.uiTitle
        detailLabel.text = recommendation.recommendationText
        dateLabel.text = recommendation.uiDateString
        
        iconImageView.image = UIImage(systemName: recommendation.uiIconName)
        iconImageView.tintColor = recommendation.uiColor
        titleLabel.textColor = recommendation.uiColor
    }
}
