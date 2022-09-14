//
//  AppleLoginHelper.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/14.
//

import SwiftUI
import Firebase
import AuthenticationServices

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
      if let err = error {
        alert(err.localizedDescription)
        return
      }
      
      guard credentialState == .authorized else {
        alert("Apple Auto login not successful")
        return
      }
      
      print("Apple Auto login successful")
      LoginManager.shared.notifyLoginSuccess(type: .apple)
      alert(nil)
      
    }
  }
  
}

extension AppleLoginHelper: ASAuthorizationControllerDelegate {
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    
    guard let nonce = currentNonce,
          let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let appleIDToken = appleIDCredential.identityToken,
          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      self.didComplete?("Something wrong please try again!")
      return
    }
    
    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                              idToken: idTokenString,
                                              rawNonce: nonce)
    
    Auth.auth().signIn(with: credential) { authResult, err in
      if let err = err {
        self.didComplete?(err.localizedDescription)
        return
      }
      // 在此取得使用者資訊 Apple user?.profile
//      let userName = self.keychainHelper.getValue(KeychainHelper.Keys.appleUserName.rawValue)
//      let photoURL = authResult.user.photoURL?.absoluteString ?? ""
//      let userIdentifier = appleIDCredential.user
//      let givenName = appleIDCredential.fullName?.givenName ?? ""
//      let familyName = appleIDCredential.fullName?.familyName ?? ""
//      let email = appleIDCredential.email ?? ""
//      let identityToken = idTokenString
//      let name: String
//      if let userName = userName {
//          name = userName
//      } else {
//          // apple登入只有第一次拿得到fullName，需要存起來
//          name = "\(familyName)\(givenName)"
//          self.keychainHelper.setKey(KeychainHelper.Keys.appleUserName.rawValue, to: "\(familyName)\(givenName)")
//      }
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
