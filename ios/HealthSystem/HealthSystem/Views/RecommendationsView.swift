//
//  RecommendationsView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import UIKit
import SnapKit

final class RecommendationsView: UIView {

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(RecommendationCell.self, forCellReuseIdentifier: RecommendationCell.identifier)
        return tableView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No insights available yet.\nTry syncing new data!"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(tableView)
        addSubview(emptyStateLabel)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        tableView.isHidden = true
        emptyStateLabel.isHidden = false
    }

    func toggleEmptyState(isEmpty: Bool) {
        tableView.isHidden = isEmpty
        emptyStateLabel.isHidden = !isEmpty
    }
}
