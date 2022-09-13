//
//  LoginManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
import Firebase
import GoogleSignIn

class LoginManager: ObservableObject {
  
  enum LoginType: String {
    case mail = "mail"
    case google = "google"
    case guest = "guest"
  }
  
  @Published var isLogin: Bool = false
  
  @Published var inputMail = UserDefaults.get(forKey: .rememberMailKey) as? String ?? ""
  
  @Published var inputPass = UserDefaults.get(forKey: .rememberPassKey) as? String ?? ""
  
  @Published var googleProfile: GIDProfileData? = GIDSignIn.sharedInstance.currentUser?.profile
  
  @Published var loginType: LoginType = LoginType(rawValue: UserDefaults.get(forKey: .loginTypeKey) as? String ?? "guest") ?? .guest
  
  static let shared = LoginManager()
  
  func getEmail() -> String {
    switch loginType {
    case .mail:
      return inputMail
    case .google:
      return googleProfile?.email ?? "Google Email Empty"
    case .guest:
      return "Email Empty"
    }
  }
  
  /// 新增登入觀察者
  func addObserverLogin(using block: ((Notification) -> Void)? = nil) {
    NotificationCenter.add(forKey: .isLoginKey) { notification in
      block?(notification)
    }
  }
  
  /// 通知目前為登入成功狀態
  func notifyLoginSuccess(type: LoginType) {
    if type == .mail {
      
      UserDefaults.set(LoginManager.shared.inputMail, forKey: .rememberMailKey)
      UserDefaults.set(LoginManager.shared.inputPass, forKey: .rememberPassKey)
      
    }
    UserDefaults.set(type.rawValue, forKey: .loginTypeKey)
    NotificationCenter.post(forKey: .isLoginKey)
    LoginManager.shared.isLogin = true
    LoginManager.shared.loginType = type
  }
  
  /// 執行登出
  func logout() {
    GIDSignIn.sharedInstance.signOut()
    
    do {
      try Auth.auth().signOut()
      LoginManager.shared.isLogin = false
      LoginManager.shared.googleProfile = nil
      UserDefaults.remove(forKey: .rememberMailKey)
      UserDefaults.remove(forKey: .rememberPassKey)
      UserDefaults.remove(forKey: .loginTypeKey)
      NotificationCenter.post(forKey: .isLoginKey)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  /// 執行刪除帳號並登出
  func deleteAccount() {
    Auth.auth().currentUser?.delete { _ in
      LoginManager.shared.logout()
    }
  }
  
  /// 執行確認登入
  func login(alert: @escaping ((_ err: String?)->Void)) {
    
    guard inputMail != "" && inputPass != "" else {
      alert("Please fill all the contents properly")
      return
    }
    Auth.auth().signIn(withEmail: inputMail, password: inputPass) { (res, err) in
      if let err = err {
        alert(err.localizedDescription)
        return
      }
      // 成功登入
      LoginManager.shared.notifyLoginSuccess(type: .mail)
      alert(nil)
    }
  }
  
  /// 執行自動登入
  func autoLogin(callback: ((_ isSuccess: Bool)->Void)? = nil) {
    
    LoginManager.shared.googleAutoLogin { err in
      if let err = err {
        print("\(err) try to login by email")
        
        LoginManager.shared.login { err in
          if let err = err {
            print(err)
            callback?(false)
          }else {
            print("AutoLogin Success")
            callback?(true)
          }
          return
        }
        
      }else {
        print("Google AutoLogin Success")
        callback?(true)
      }
      return
    }
    
  }
  
  /// 執行註冊帳號 成功並帶登入
  func register(pass: String, repass: String,
                alert: @escaping ((_ isSuccess: Bool, _ msg: String)->Void)) {
    
    guard LoginManager.shared.inputMail != "" && pass != "" && repass != "" else {
      alert(false, "Please fill all the contents properly")
      return
    }
    
    guard pass == repass else {
      alert(false, "Password mismatch")
      return
    }
    
    LoginManager.shared.inputPass = pass
    
    Auth.auth().createUser(withEmail: inputMail, password: pass) { (res, err) in
      
      if let err = err {
        alert(false, err.localizedDescription)
        return
      }
      
      UserDefaults.set(LoginManager.shared.inputMail, forKey: .rememberMailKey)
      UserDefaults.set(LoginManager.shared.inputPass, forKey: .rememberPassKey)
      
      // 成功註冊
      alert(true, "Register Success Welcome!\nLogin now?")
      
    }
  }
  
  
  /// 執行重新設定密碼 信箱認證
  func resetPassword(alert: @escaping ((_ title: String, _ msg: String)->Void)) {
    guard inputMail != "" else {
      alert("Error", "Email is empty")
      return
    }
    Auth.auth().sendPasswordReset(withEmail: inputMail) { (err) in
      if let err = err {
        alert("Error", err.localizedDescription)
        return
      }
      
      alert("Reset Success", "Password reset link has been sent successfully")
    }
  }
  
}

extension LoginManager {
  
  func googleAutoLogin(alert: @escaping ((_ err: String?)->Void)) {
    guard GIDSignIn.sharedInstance.hasPreviousSignIn() else {return}
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, err in
      if let err = err {
        print(err.localizedDescription)
        return
      }
      
      guard let authentication = user?.authentication,
            let idToken = authentication.idToken else { return }
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
      
      Auth.auth().signIn(with: credential) { (_, err) in
        if let err = err {
          alert(err.localizedDescription)
          return
        }
        LoginManager.shared.googleProfile = user?.profile
        LoginManager.shared.notifyLoginSuccess(type: .google)
        alert(nil)
        
      }
      
    }
    
  }
  
  func googleLogin(alert: @escaping ((_ err: String?)->Void)) {
    
    guard let clientID = FirebaseApp.app()?.options.clientID else { return }
    let configuration = GIDConfiguration(clientID: clientID)
    
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
    guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
    
    GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) { user, err in
      if let err = err {
        print(err.localizedDescription)
        return
      }
      
      guard let authentication = user?.authentication,
            let idToken = authentication.idToken else { return }
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
      
      Auth.auth().signIn(with: credential) { (_, err) in
        if let err = err {
          alert(err.localizedDescription)
          return
        }
        LoginManager.shared.googleProfile = user?.profile
        LoginManager.shared.notifyLoginSuccess(type: .google)
        alert(nil)
        
      }
    }
  }
  
}
