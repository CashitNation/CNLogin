//
//  MainView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI

struct MainView: View {
  
  @ObservedObject private var loginManager = LoginManager.shared
  
    var body: some View {
        VStack {
            
            Text("MainView")
            
            Button {
              loginManager.logout()
            } label: {
                Text("Log out")
            }
            .padding()
            
            Button {
              loginManager.deleteAccount()
            } label: {
                Text("Delete Account")
            }
            .padding()

            
        }
    }
    
}
