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
    
    NavigationView {
      ZStack {
        
        if loginManager.isLogin {
          MainView()
        }else {
          CNLoginPageView()
        }
        
      }
      .navigationTitle("")
      .navigationBarHidden(true)
      .navigationBarBackButtonHidden(true)
      .onAppear {
        
        loginManager.addObserverLogin()
        loginManager.autoLogin { isSuccess in
          loginManager.isLogin = isSuccess
        }
        
      }
    }
    
  }
  
}
