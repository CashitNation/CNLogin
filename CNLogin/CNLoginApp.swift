//
//  CNLoginApp.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI
import Firebase

@main
struct CNLoginApp: App {
  
  init () {
    FirebaseApp.configure()
  }
  
  var body: some Scene {
    WindowGroup {
      SplashView()
    }
  }
}
