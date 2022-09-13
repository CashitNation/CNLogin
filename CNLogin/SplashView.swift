//
//  SplashView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI
import Firebase

struct SplashView: View {
  
  @ObservedObject private var loginManager = LoginManager.shared
  
  @State private var isChecking: Bool = true
  
  var body: some View {
    
    NavigationView {
      ZStack {
        if isChecking {
          ActivityIndicator(isAnimating: .constant(true),
                            style: .large)
        } else if loginManager.isLogin {
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
          self.isChecking = !isSuccess
        }
        
      }
    }
    
  }
  
}
