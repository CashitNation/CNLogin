//
//  MainTabBarView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI

struct MainTabBarView: View {
  
  var body: some View {
    TabView {
      
      Text("Home")
        .tabItem {
          Image(systemName: "house")
          Text("Home")
        }
      
      UserInfoView()
        .tabItem {
          Image(systemName: "person")
          Text("User")
        }
      
    }
  }
  
}

struct UserInfoView: View {
  @StateObject private var loginManager = LoginManager.shared
  var body: some View {
    
    VStack {
      
      Text("name: \(loginManager.getUser()?.displayName ?? "")")
      
      Text("mail: \(loginManager.getUser()?.email ?? "")")
      
      Button {
        loginManager.action(type: .logout)
      } label: {
        Text("Log out")
      }
      .padding()
      
      Button {
        loginManager.action(type: .deleteAccount)
      } label: {
        Text("Delete Account")
      }
      .padding()
    }
    
  }
}
