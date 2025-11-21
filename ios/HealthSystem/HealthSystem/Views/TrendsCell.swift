//
//  TrendsCell.swift
//  HealthSystem
//
//  Created by Elina Karimova on 20/11/25.
//

import UIKit
import SnapKit

final class TrendsCell: UITableViewCell {
    
    static let reuseIdentifier = "TrendCell"
    
    // MARK: - UI Components
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let sleepLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemPurple
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let hrLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [stepsLabel, sleepLabel, hrLabel])
        stack.axis = .horizontal
        stack.spacing = 15
        stack.distribution = .fillEqually
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        contentView.addSubview(dateLabel)
        contentView.addSubview(stackView)
        
        let separator = UIView()
        separator.backgroundColor = .lightGray.withAlphaComponent(0.3)
        contentView.addSubview(separator)
        
        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(15)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(15)
        }
        
        separator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with summary: DailySummary) {
        
        var dateStr = "Unknown Date"
        if let d = summary.date, d.count == 3 {
            let components = DateComponents(year: d[0], month: d[1], day: d[2])
            let calendar = Calendar.current
            
            if let date = calendar.date(from: components) {
                 let formatter = DateFormatter()
                 formatter.dateStyle = .medium
                 formatter.locale = Locale(identifier: "en_EN")
                 dateStr = formatter.string(from: date)
            }
        }
        
        dateLabel.text = dateStr
        
        let steps = summary.stepsTotal ?? 0
        let sleep = summary.sleepHoursTotal ?? 0.0
        let hr = Int((summary.hrMean ?? 0.0).rounded())
        
        stepsLabel.text = "👣 \(steps)"
        sleepLabel.text = "🌙 \(String(format: "%.1f", sleep)) h"
        hrLabel.text = "❤️ \(hr) bpm"
    }
}
