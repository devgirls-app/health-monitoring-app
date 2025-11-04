//
//  RecommendationsViewController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 3/11/25.
//

import UIKit
import SnapKit

final class RecommendationsViewController: UIViewController {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Здесь будут рекомендации от ML 💡"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
}
