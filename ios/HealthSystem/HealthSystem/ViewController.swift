//
//  ViewController.swift
//  HealthSystem
//
//  Created by Elina Karimova on 15/10/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
<<<<<<< HEAD
        view.backgroundColor = .systemBackground
        
        HealthKitManager.shared.requestAuthorization { success, error in
            guard success else { print("Permission denied"); return }

            // Fetch actual steps from HealthKit
            HealthKitManager.shared.fetchSteps(for: Date()) { steps, err in
                guard let steps = steps else {
                    print("Failed to fetch steps:", err?.localizedDescription ?? "unknown error")
                    return
                }

                // Build DTO with real step count
                let dto = HealthDataDTO(
                    userId: 1,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    heartRate: 72,       // you can also fetch real heart rate with fetchHeartRate()
                    steps: Int(steps),
                    calories: 250.0,
                    sleepHours: 7.5,
                    source: "iPhone"
                )

                // Send to backend
                NetworkManager.shared.postHealthData(dto) { result in
                    switch result {
                    case .success():
                        print("Data sent successfully ✅")
                    case .failure(let err):
                        print("Error sending data: \(err)")
                    }
                }
            }
        }

        
    }
}
=======
        view.backgroundColor = .red
    }


}

>>>>>>> origin/ios-full-restore
