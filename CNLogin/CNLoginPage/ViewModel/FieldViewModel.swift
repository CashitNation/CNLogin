//
//  FieldViewModel.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/15.
//

import Foundation

class FieldViewModel: ObservableObject {
  
  // 登入 使否顯示密碼
  @Published var signInVisible = false
  
  // 註冊 使否顯示密碼
  @Published var signUpVisible = false
  @Published var signUprevisible = false
  
  // 信箱
  @Published var signMail = UserDefaults.get(forKey: .rememberMailKey) as? String ?? ""
  
  // 登入密碼
  @Published var signInPass = UserDefaults.get(forKey: .rememberPassKey) as? String ?? ""
  
  // 註冊密碼
  @Published var signUpPass = ""
  @Published var signUpRepass = ""
  
  
  enum SignField: Hashable { case inMail, inPass, upMail, upPass, upRepass  }
  
  
}
