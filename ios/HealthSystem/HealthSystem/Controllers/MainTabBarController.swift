//
//  TabBarController.swift
//  HealthSystem
//
//  Created by Aruuke Turgunbaeva on 3/11/25.
//

import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dashboard = UINavigationController(rootViewController: DashboardViewController())
        dashboard.tabBarItem = UITabBarItem(title: "Главная",
                                            image: UIImage(systemName: "house.fill"),
                                            tag: 0)
        
        let trends = UINavigationController(rootViewController: TrendsViewController())
        trends.tabBarItem = UITabBarItem(title: "Тренды",
                                         image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
                                         tag: 1)
        
        let recs = UINavigationController(rootViewController: RecommendationsViewController())
        recs.tabBarItem = UITabBarItem(title: "Советы",
                                       image: UIImage(systemName: "lightbulb.fill"),
                                       tag: 2)
        
        let profile = UINavigationController(rootViewController: ProfileViewController())
        profile.tabBarItem = UITabBarItem(title: "Профиль",
                                          image: UIImage(systemName: "person.crop.circle.fill"),
                                          tag: 3)
        
        viewControllers = [dashboard, trends, recs, profile]
    }
}
