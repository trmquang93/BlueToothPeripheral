//
//  AppDelegate.swift
//  BluetoothPeripheral
//
//  Created by Quang Tran on 30/03/2022.
//

import UIKit


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        loadRootViewController()
        
        return true
    }
    
    
}

extension AppDelegate {
    func loadRootViewController() {
        let window = self.window ?? UIWindow()
        
        window.makeKeyAndVisible()
        
        window.rootViewController = AppDelegate.createRootViewController()
        
        self.window = window
    }
    
    static func createRootViewController() -> UIViewController {
        let viewController = ViewController()
        
        return viewController
    }
}

