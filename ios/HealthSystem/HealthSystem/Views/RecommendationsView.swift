//
//  RecommendationsView.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 18/11/25.
//

import UIKit
import SnapKit

class RecommendationsView: UIView {
    
    let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .systemGroupedBackground
        tv.separatorStyle = .none
        tv.register(RecommendationCell.self, forCellReuseIdentifier: RecommendationCell.identifier)
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return tv
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No recommendations yet"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGroupedBackground
        addSubview(tableView)
        addSubview(emptyStateLabel)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toggleEmptyState(isEmpty: Bool) {
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}
