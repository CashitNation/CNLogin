//
//  LoginManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
import Firebase

enum LoginType: String {
  case mail = "mail"
  case facebook = "facebook"
  case google = "google"
  case apple = "apple"
  case guest = "guest"
  
  var iconUrl: String {
    switch self {
    case .facebook: return "https://cdn-icons-png.flaticon.com/512/124/124010.png"
    case .google: return "https://cdn-icons-png.flaticon.com/512/300/300221.png"
    case .apple: return "https://cdn-icons-png.flaticon.com/512/0/747.png"
    default: return ""
    }
  }
}

class LoginManager: ObservableObject {
  
  @Published var isLogin: Bool = false
  
  @Published var isLoading: Bool = true
  
  @Published var loginType: LoginType = LoginType(rawValue: UserDefaults.get(forKey: .loginTypeKey) as? String ?? "guest") ?? .guest
  
  @Published var isSuccessRegister = false
  
  private lazy var fbHelper = FBLoginHelper()
  private lazy var googleHelper = GoogleLoginHelper()
  private lazy var appleHelper = AppleLoginHelper()
  
  var needToShowAlert: ((_ title: String?, _ msg: String?)->Void)?
  
  static let shared = LoginManager()
  
  private init() {
    
    fbHelper.didLoginComplete = {
      [weak self] isSuccess, msg in
      guard let self = self else {return}
      if let isSuccess = isSuccess {
        self.needToShowAlert?(isSuccess ? "Success" : "Error", msg)
      }else {
        self.needToShowAlert?(nil, nil)
      }
    }
    
    googleHelper.didLoginComplete = {
      [weak self] isSuccess, msg in
      guard let self = self else {return}
      if let isSuccess = isSuccess {
        self.needToShowAlert?(isSuccess ? "Success" : "Error", msg)
      }else {
        self.needToShowAlert?(nil, nil)
      }
    }
    
    appleHelper.didLoginComplete = {
      [weak self] isSuccess, msg in
      guard let self = self else {return}
      if let isSuccess = isSuccess {
        self.needToShowAlert?(isSuccess ? "Success" : "Error", msg)
      }else {
        self.needToShowAlert?(nil, nil)
      }
    }
    
  }
  
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
      self.needToShowAlert?(nil, nil)
    }
  }
  
}

// MARK: 登入方法
extension LoginManager {
  
  enum LoginAction {
    case autoLogin
    case mailLogin(mail: String, pass: String)
    case fbLogin
    case googleLogin
    case appleLogin
  }
  
  func loginAction(type: LoginAction) {
    switch type {
    case .autoLogin:
      autoLogin()
    case .mailLogin(let mail, let pass):
      mailLogin(mail: mail, pass: pass)
    case .fbLogin:
      fbHelper.facebookLogin()
    case .googleLogin:
      googleHelper.googleLogin()
    case .appleLogin:
      appleHelper.appleLogin()
    }
  }
  
  /// 執行自動登入
  private func autoLogin() {
    
    guard let user = Auth.auth().currentUser else {
      needToShowAlert?(nil, nil)
      return
    }
    print("@@ \(user.uid) \(user.email ?? "Empty Email") auto login with \(LoginManager.shared.loginType)")
    switch LoginManager.shared.loginType {
    case .mail:
      let mail = UserDefaults.get(forKey: .rememberMailKey) as? String ?? ""
      let pass = UserDefaults.get(forKey: .rememberPassKey) as? String ?? ""
      mailLogin(mail: mail, pass: pass)
    case .facebook:
      fbHelper.facebookLogin(isAutoLogin: true)
    case .google:
      googleHelper.googleAutoLogin()
    case .apple:
      appleHelper.appleAutoLogin()
    case .guest:
      needToShowAlert?(nil, nil)
    }
    
  }
  
  /// 執行信箱登入
  private func mailLogin(mail:String, pass: String) {
    
    guard mail != "" && pass != "" else {
      needToShowAlert?("Error", "Please fill all the contents properly")
      return
    }
    Auth.auth().signIn(withEmail: mail, password: pass) {
      [weak self] res, err in
      guard let self = self else {return}
      
      if let err = err {
        self.needToShowAlert?("Error", err.localizedDescription)
        return
      }
      UserDefaults.set(mail, forKey: .rememberMailKey)
      UserDefaults.set(pass, forKey: .rememberPassKey)
      // 成功登入
      LoginManager.shared.notifyLoginSuccess(type: .mail)
    }
  }
  
}

// MARK: 註冊/忘記密碼方法
extension LoginManager {
  
  /// 執行註冊帳號 成功並帶登入
  func register(mail: String, pass: String, repass: String) {
    
    guard mail != "" && pass != "" && repass != "" else {
      self.needToShowAlert?("Error", "Please fill all the contents properly")
      return
    }
    
    guard pass == repass else {
      self.needToShowAlert?("Error", "Password mismatch")
      return
    }
    
    Auth.auth().createUser(withEmail: mail, password: pass) {
      [weak self] res, err in
      guard let self = self else {return}
      
      if let err = err {
        self.needToShowAlert?("Error", err.localizedDescription)
        return
      }
      
      UserDefaults.set(mail, forKey: .rememberMailKey)
      UserDefaults.set(pass, forKey: .rememberPassKey)
      self.isSuccessRegister = true
      // 成功註冊
      self.needToShowAlert?("Success", "Register Success Welcome!\nLogin now?")
      
    }
  }
  
  /// 執行重新設定密碼 信箱認證
  func resetPassword(mail: String) {
    guard mail != "" else {
      self.needToShowAlert?("Error", "Email is empty")
      return
    }
    Auth.auth().sendPasswordReset(withEmail: mail) {
      [weak self] err in
      guard let self = self else {return}
      if let err = err {
        self.needToShowAlert?("Error", err.localizedDescription)
        return
      }
      
      self.needToShowAlert?("Reset Success", "Password reset link has been sent successfully")
    }
  }
  
}

// MARK: 登出刪除帳號
extension LoginManager {
  
  /// 執行登出
  func logout(callback: (()->Void)? = nil) {
    
    googleHelper.googleLogout()
    fbHelper.facebookLogout()
    
    do {
      try Auth.auth().signOut()
      LoginManager.shared.isLogin = false
      UserDefaults.remove(forKey: .loginTypeKey)
      UserDefaults.remove(forKey: .appleUserIdKey)
      NotificationCenter.post(forKey: .isLoginKey)
      callback?()
    } catch {
      print(error.localizedDescription)
      callback?()
    }
  }
  
  /// 執行刪除帳號並登出
  func deleteAccount(callback: (()->Void)? = nil) {
    Auth.auth().currentUser?.delete { _ in
      LoginManager.shared.logout(callback: callback)
    }
  }
  
}
