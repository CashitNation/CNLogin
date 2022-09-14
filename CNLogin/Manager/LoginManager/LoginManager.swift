//
//  LoginManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
import Firebase

class LoginManager: ObservableObject {
  
  enum LoginType: String {
    case mail = "mail"
    case facebook = "facebook"
    case google = "google"
    case apple = "apple"
    case guest = "guest"
  }
  
  @Published var isLogin: Bool = false
  
  @Published var inputMail = UserDefaults.get(forKey: .rememberMailKey) as? String ?? ""
  
  @Published var inputPass = UserDefaults.get(forKey: .rememberPassKey) as? String ?? ""
  
  @Published var loginType: LoginType = LoginType(rawValue: UserDefaults.get(forKey: .loginTypeKey) as? String ?? "guest") ?? .guest
  
  static let shared = LoginManager()
  
  private init() {}
  
  private lazy var facebookHelper: FBLoginHelper = {
    return FBLoginHelper()
  }()
  
  private lazy var googleHelper: GoogleLoginHelper = {
    return GoogleLoginHelper()
  }()
  
  private lazy var appleHelper: AppleLoginHelper = {
    return AppleLoginHelper()
  }()
  
  lazy var didAppleLoginComplete: ((_ err: String?)->Void)? = appleHelper.didComplete
  
  func getEmail() -> String? {
    return Auth.auth().currentUser?.email
  }
  
  /// 新增登入觀察者
  func addObserverLogin(using block: ((Notification) -> Void)? = nil) {
    NotificationCenter.add(forKey: .isLoginKey) { notification in
      block?(notification)
    }
  }
  
  /// 通知目前為登入成功狀態
  func notifyLoginSuccess(type: LoginType) {
    print("@@ LoginSuccess by \(type.rawValue)")
    DispatchQueue.main.async {
      LoginManager.shared.isLogin = true
      LoginManager.shared.loginType = type
      UserDefaults.set(type.rawValue, forKey: .loginTypeKey)
      NotificationCenter.post(forKey: .isLoginKey)
    }
  }
  
  /// 執行登出
  func logout() {
    
    googleHelper.googleLogout()
    facebookHelper.facebookLogout()
    
    do {
      try Auth.auth().signOut()
      LoginManager.shared.isLogin = false
      UserDefaults.remove(forKey: .loginTypeKey)
      UserDefaults.remove(forKey: .appleUserIdKey)
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
  
  /// 執行自動登入
  func autoLogin() {
    
    if let user = Auth.auth().currentUser {
      print("@@ \(user.uid) \(user.displayName ?? "無") auto login with \(LoginManager.shared.loginType)")
      switch LoginManager.shared.loginType {
      case .mail:
        LoginManager.shared.mailLogin { err in
          if let err = err {
            print(err.description)
            LoginManager.shared.isLogin = false
            return
          }
        }
      case .facebook:
        facebookHelper.facebookLogin { err in
          if let err = err {
            print(err.description)
            LoginManager.shared.isLogin = false
            return
          }
        }
      case .google:
        googleHelper.googleAutoLogin { err in
          if let err = err {
            print(err.description)
            LoginManager.shared.isLogin = false
            return
          }
        }
      case .apple:
        appleHelper.appleAutoLogin { err in
          if let err = err {
            print(err.description)
            LoginManager.shared.isLogin = false
            return
          }
        }
      case .guest:
        print("@@ not auto login")
        LoginManager.shared.isLogin = false
        return
      }
    } else {
      print("@@ not auto login")
      LoginManager.shared.isLogin = false
    }
    
  }
  
  /// 執行信箱登入
  func mailLogin(alert: @escaping ((_ err: String?)->Void)) {
    
    guard inputMail != "" && inputPass != "" else {
      alert("Please fill all the contents properly")
      return
    }
    Auth.auth().signIn(withEmail: inputMail, password: inputPass) { (res, err) in
      if let err = err {
        alert(err.localizedDescription)
        return
      }
      UserDefaults.set(LoginManager.shared.inputMail, forKey: .rememberMailKey)
      UserDefaults.set(LoginManager.shared.inputPass, forKey: .rememberPassKey)
      // 成功登入
      LoginManager.shared.notifyLoginSuccess(type: .mail)
      alert(nil)
    }
  }
  
  func googleLogin(alert: @escaping ((_ err: String?)->Void)) {
    googleHelper.googleLogin(alert: alert)
  }
  
  func appleLogin() {
    appleHelper.appleLogin()
  }
  
  func facebookLogin(alert: @escaping ((_ err: String?)->Void)) {
    facebookHelper.facebookLogin(alert: alert)
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
