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
        
        let dashboard = UINavigationController(rootViewController: DashboardController())
        dashboard.tabBarItem = UITabBarItem(title: "Home",
                                            image: UIImage(systemName: "house.fill"),
                                            tag: 0)
        
        let trends = UINavigationController(rootViewController: TrendsController())
        trends.tabBarItem = UITabBarItem(title: "Trends",
                                         image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
                                         tag: 1)
        
        let recs = UINavigationController(rootViewController: RecommendationsController())
        recs.tabBarItem = UITabBarItem(title: "Recommendations",
                                       image: UIImage(systemName: "lightbulb.fill"),
                                       tag: 2)
        
        let profile = UINavigationController(rootViewController: ProfileController())
        profile.tabBarItem = UITabBarItem(title: "Profile",
                                          image: UIImage(systemName: "person.crop.circle.fill"),
                                          tag: 3)
        
        viewControllers = [dashboard, trends, recs, profile]
    }
}
