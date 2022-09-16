//
//  SplashView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI

struct SplashView: View {
  
  @StateObject private var loginManager = LoginManager.shared
  
  var body: some View {
    
      ZStack {
        
        if loginManager.isLogin {
          MainView()
        }else {
          CNLoginPageView()
        }
        
      }
      .onAppear {
        loginManager.addObserverLogin()
      }
    
  }
  
}
