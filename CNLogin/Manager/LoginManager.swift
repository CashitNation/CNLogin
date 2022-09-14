//
//  LoginManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
import Firebase
import GoogleSignIn
import AuthenticationServices

class LoginManager: ObservableObject {
  
  enum LoginType: String {
    case mail = "mail"
    case google = "google"
    case apple = "apple"
    case guest = "guest"
  }
  
  @Published var isLogin: Bool = false
  
  @Published var inputMail = UserDefaults.get(forKey: .rememberMailKey) as? String ?? ""
  
  @Published var inputPass = UserDefaults.get(forKey: .rememberPassKey) as? String ?? ""
  
  @Published var googleProfile: GIDProfileData? = GIDSignIn.sharedInstance.currentUser?.profile
  
  @Published var loginType: LoginType = LoginType(rawValue: UserDefaults.get(forKey: .loginTypeKey) as? String ?? "guest") ?? .guest
  
  static let shared = LoginManager()
  
  lazy var googleHelper: GoogleLoginHelper = {
      return GoogleLoginHelper()
  }()
  
  lazy var appleHelper: AppleLoginHelper = {
      return AppleLoginHelper()
  }()
  
  func getEmail() -> String {
    switch loginType {
    case .mail:
      return inputMail
    case .google:
      return googleProfile?.email ?? "Google Email Empty"
    case .apple:
      return "Apple Email Empty"
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
    GIDSignIn.sharedInstance.signOut()
    
    do {
      try Auth.auth().signOut()
      LoginManager.shared.isLogin = false
      LoginManager.shared.googleProfile = nil
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
        break
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

class GoogleLoginHelper: NSObject {
  
  func googleAutoLogin(alert: @escaping ((_ err: String?)->Void)) {
    
    guard GIDSignIn.sharedInstance.hasPreviousSignIn() else {
      alert("hasNotPreviousSignIn")
      return
    }
    
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
      
      Auth.auth().signIn(with: credential) { authResult, err in
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

class AppleLoginHelper: NSObject {
  
  private lazy var keychainHelper: KeychainHelper = {
      return KeychainHelper()
  }()
  
  private var currentNonce: String?
  
  var didComplete: ((_ err: String?)->Void)? = nil
  
  func appleLogin() {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    let nonce = String.randomNonceString()
    currentNonce = nonce
    request.requestedScopes = [.email, .fullName]
    request.nonce = nonce.sha256()
    
    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
  }
  
  func appleAutoLogin(alert: @escaping ((_ err: String?)->Void)) {
    
    let userId = UserDefaults.get(forKey: .appleUserIdKey) as? String ?? ""
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    
    appleIDProvider.getCredentialState(forUserID: userId) { (credentialState, error) in
      switch credentialState {
      case .authorized:
        print("Auto login successful")
        LoginManager.shared.notifyLoginSuccess(type: .apple)
        alert(nil)
        break
      case .revoked, .notFound:
        alert("apple Auto login not successful")
        break
      default:
        alert("Unknow Error apple Auto login not successful")
        break
      }
    }
  }
  
}

extension AppleLoginHelper: ASAuthorizationControllerDelegate {
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    
    guard let nonce = currentNonce,
          let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let appleIDToken = appleIDCredential.identityToken,
          let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
    
    
    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                              idToken: idTokenString,
                                              rawNonce: nonce)
    
    Auth.auth().signIn(with: credential) { authResult, err in
      if let err = err {
        self.didComplete?(err.localizedDescription)
        return
      }
      
      UserDefaults.set(appleIDCredential.user, forKey: .appleUserIdKey)
      LoginManager.shared.notifyLoginSuccess(type: .apple)
      self.didComplete?(nil)
      
    }
  }
  
  /// Apple登入失敗
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    print("Apple登入失敗： \(error.localizedDescription)")
  }
  
}

extension AppleLoginHelper: ASAuthorizationControllerPresentationContextProviding {
  
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first
    return window ?? UIWindow()
  }
    
}
  
struct SignInWithAppleButton: UIViewRepresentable {
  
  typealias UIViewType = ASAuthorizationAppleIDButton
  
  func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
    return ASAuthorizationAppleIDButton(type: .signIn, style: .white)
  }
  
  func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
  
}
