//
//  LoginManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
import Firebase

class LoginManager: ObservableObject {
  
  /// 當前頁面 登入/註冊 狀態
  @Published var signState: SignState = .signIn
  
  /// 當前登入狀態是否登入
  @Published var isLogin: Bool = false
  
  /// 當前是否正在讀取中
  @Published var isLoading: Bool = true
  
  /// 當前登入類型
  @Published var loginType: LoginType = LoginType(rawValue: UserDefaults.get(forKey: .loginTypeKey) as? String ?? "guest") ?? .guest
  
  /// 是否為成功註冊
  @Published var isSuccessRegister = false
  
  /// Facebook
  private lazy var fbHelper = FBLoginHelper()
  
  /// Google
  private lazy var googleHelper = GoogleLoginHelper()
  
  /// Apple
  private lazy var appleHelper = AppleLoginHelper()
  
  /// 顯示彈窗內容
  var needToShowAlert: ((_ title: String?, _ msg: String?)->Void)?
  
  static let shared = LoginManager()
  
  private init() {
    setupDidLoginComplete()
  }
  
  func getEmail() -> String? {
    return Auth.auth().currentUser?.email
  }
  
}

/// 登入狀態相關
extension LoginManager {
  
  /// 當前畫面登入/註冊狀態
  enum SignState {
    case signIn, signUp
    var btnText: String {
      switch self {
      case .signIn: return "Sign In"
      case .signUp: return "Sign Up"
      }
    }
  }
  
  /// 當前登入狀態相關
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
  
  func getThirdPartIconUrl(type: LoginType) -> String {
    return type.iconUrl
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
  
  /// 設定登入完成的Complete
  private func setupDidLoginComplete() {
    
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
  
}

// MARK: 登入/註冊/重設密碼/登出/刪除帳號
extension LoginManager {
  
  /// 執行動作種類
  enum ActionType {
    case autoLogin
    case mailLogin(mail: String, pass: String)
    case fbLogin
    case googleLogin
    case appleLogin
    case register(mail: String, pass: String, repass: String)
    case resetPassword(mail: String)
    case logout
    case deleteAccount
  }
  
  /// 執行動作
  func action(type: ActionType) {
    isLoading = true
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
    case .register(let mail, let pass, let repass):
      register(mail: mail, pass: pass, repass: repass)
    case .resetPassword(let mail):
      resetPassword(mail: mail)
    case .logout:
      logout()
    case .deleteAccount:
      deleteAccount()
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
  
  /// 執行註冊帳號 成功並帶登入
  private func register(mail: String, pass: String, repass: String) {
    
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
  private func resetPassword(mail: String) {
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
  
  /// 執行登出
  private func logout(callback: (()->Void)? = nil) {
    
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
  private func deleteAccount(callback: (()->Void)? = nil) {
    Auth.auth().currentUser?.delete { _ in
      LoginManager.shared.logout(callback: callback)
    }
  }
  
}
