//
//  AppDelegate.swift
//  Zedit-UIKit
//
//  Created by Avinash on 28/10/24.
//

import UIKit
import Spezi
import SpeziLLM
import SpeziLLMLocal

@main
class AppDelegate: SpeziAppDelegate {

    static var sharedLLMRunner: LLMRunner?

        override var configuration: Configuration {
            Configuration {
                LLMRunner {
                    LLMLocalPlatform()
                }
            }
        }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let runner = LLMRunner()
        AppDelegate.sharedLLMRunner = runner
        return true
    }

    // MARK: UISceneSession Lifecycle

    override func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle scene session discard if needed.
    }
}
