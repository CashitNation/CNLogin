//
//  CNLoginApp.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import UIKit
import SwiftUI
import Firebase
import FBSDKCoreKit

@main
struct CNLoginApp: App {
  
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      SplashView()
    }
  }
  
  class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      
      ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions
      )
      
      FirebaseApp.configure()
      
      return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      
      return ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation]
      )
    }
  }
}
