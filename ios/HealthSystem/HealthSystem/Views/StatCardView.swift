//
//  StatCardView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 3/11/25.
//

import UIKit
import SnapKit

final class StatCardView: UIView {
    
    private let iconLabel = UILabel()
    private let valueLabel = UILabel()
    private let nameLabel = UILabel()
    
    init(icon: String, value: String, label: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 30)
        
        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 20)
        
        nameLabel.text = label
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = .secondaryLabel
        
        addSubview(iconLabel)
        addSubview(valueLabel)
        addSubview(nameLabel)
        
        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(8)
            make.leading.equalTo(iconLabel)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(4)
            make.leading.equalTo(iconLabel)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
