//
//  LoginManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
import Firebase

class LoginManager: ObservableObject {
  
  @Published var isLogin: Bool = UserDefaults.get(forKey: .isLoginKey) as? Bool ?? false
  
  @Published var mail = UserDefaults.get(forKey: .rememberMailKey) as? String ?? ""
  
  @Published var pass = UserDefaults.get(forKey: .rememberPassKey) as? String ?? ""
  
  static let shared = LoginManager()
  
  /// 新增登入觀察者
  func addObserverLogin(using block: ((Notification) -> Void)? = nil) {
    NotificationCenter.add(forKey: .isLoginKey) { notification in
      LoginManager.shared.isLogin = UserDefaults.get(forKey: .isLoginKey) as? Bool ?? false
      block?(notification)
    }
  }
  
  /// 通知目前為登入成功狀態
  func notifyLoginSuccess() {
    UserDefaults.set(true, forKey: .isLoginKey)
    NotificationCenter.post(forKey: .isLoginKey)
    LoginManager.shared.isLogin = true
    UserDefaults.set(LoginManager.shared.mail, forKey: .rememberMailKey)
    UserDefaults.set(LoginManager.shared.pass, forKey: .rememberPassKey)
  }
  
  /// 執行登出
  func logout() {
    try! Auth.auth().signOut()
    UserDefaults.set(false, forKey: .isLoginKey)
    NotificationCenter.post(forKey: .isLoginKey)
    LoginManager.shared.isLogin = false
    UserDefaults.set("", forKey: .rememberMailKey)
    UserDefaults.set("", forKey: .rememberPassKey)
  }
  
  /// 執行刪除帳號並登出
  func deleteAccount() {
    Auth.auth().currentUser?.delete { _ in
      LoginManager.shared.logout()
    }
  }
  
  /// 執行確認登入
  func login(alert: @escaping ((_ err: String?)->Void)) {
    if mail != "" && pass != "" {
      Auth.auth().signIn(withEmail: mail, password: pass) { (res, err) in
        if let err = err {
          alert(err.localizedDescription)
          return
        }
        // 成功登入
        LoginManager.shared.notifyLoginSuccess()
        alert(nil)
      }
    }else {
      alert("Please fill all the contents properly")
    }
  }
  
  /// 執行自動登入
  func autoLogin(callback: ((_ isSuccess: Bool)->Void)? = nil) {
    LoginManager.shared.login { err in
      if let err = err {
        print(err)
        callback?(false)
      }else {
        print("AutoLogin Success")
        callback?(true)
      }
    }
  }
  
  /// 執行註冊帳號 成功並帶登入
  func register(pass: String, repass: String,
                alert: @escaping ((_ isSuccess: Bool, _ msg: String)->Void)) {
    
    guard LoginManager.shared.mail != "" && pass != "" && repass != "" else {
      alert(false, "Please fill all the contents properly")
      return
    }
    
    guard pass == repass else {
      alert(false, "Password mismatch")
      return
    }
    
    LoginManager.shared.pass = pass
    
    Auth.auth().createUser(withEmail: mail, password: pass) { (res, err) in
      
      if let err = err {
        alert(false, err.localizedDescription)
        return
      }
      
      UserDefaults.set(LoginManager.shared.mail, forKey: .rememberMailKey)
      UserDefaults.set(LoginManager.shared.pass, forKey: .rememberPassKey)
      
      // 成功註冊
      alert(true, "Register Success Welcome!\nLogin now?")
      
    }
  }


  /// 執行重新設定密碼 信箱認證
  func resetPassword(alert: @escaping ((_ title: String, _ msg: String)->Void)) {
    guard mail != "" else {
      alert("Error", "Email is empty")
      return
    }
    Auth.auth().sendPasswordReset(withEmail: mail) { (err) in
      if let err = err {
        alert("Error", err.localizedDescription)
        return
      }
      
      alert("Reset Success", "Password reset link has been sent successfully")
    }
  }
  
}
