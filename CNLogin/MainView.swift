//
//  MainView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI

struct MainView: View {
  
  @StateObject private var loginManager = LoginManager.shared
  
    var body: some View {
        VStack {
            
            Text("MainView")
            
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

          Text("\(loginManager.getEmail() ?? "Email Empty")")
        }
      
    }
    
}
