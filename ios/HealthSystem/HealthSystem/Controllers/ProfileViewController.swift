//
//  ProfileViewController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 3/11/25.
//

import UIKit
import SnapKit

final class ProfileViewController: UIViewController {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Профиль и настройки"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
