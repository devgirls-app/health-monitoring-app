//
//  TrendsView.swift
//  HealthSystem
//
//  Created by Elina Karimova on 20/11/25.
//

import UIKit
import SnapKit

final class TrendsView: UIView {
    
    // MARK: - UI Components
    lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.tableFooterView = UIView()
        return tv
    }()
    
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
    
    // MARK: - Layout
    private func setupLayout() {
        addSubview(tableView)
        addSubview(activityIndicator)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            tableView.alpha = 0.5
        } else {
            activityIndicator.stopAnimating()
            tableView.alpha = 1.0
        }
    }
}
