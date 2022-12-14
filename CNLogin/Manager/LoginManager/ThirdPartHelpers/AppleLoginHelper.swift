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
  
  var didLoginComplete: ((_ isSuccess: Bool?, _ msg: String?)->Void)?
  
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
  
  func appleAutoLogin() {
    
    let userId = UserDefaults.get(forKey: .appleUserIdKey) as? String ?? ""
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    
    appleIDProvider.getCredentialState(forUserID: userId) {
      [weak self] (credentialState, error) in
      guard let self = self else {return}
      if let err = error {
        self.didLoginComplete?(false, err.localizedDescription)
        return
      }
      
      guard credentialState == .authorized else {
        self.didLoginComplete?(false, "Apple Auto login not successful")
        return
      }
      
      print("Apple Auto login successful")
      LoginManager.shared.notifyLoginSuccess(type: .apple)
      self.didLoginComplete?(true, nil)
      
    }
  }
  
}

extension AppleLoginHelper: ASAuthorizationControllerDelegate {
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    
    guard let nonce = currentNonce,
          let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let appleIDToken = appleIDCredential.identityToken,
          let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      self.didLoginComplete?(false, "Something wrong please try again!")
      return
    }
    
    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                              idToken: idTokenString,
                                              rawNonce: nonce)
    
    Auth.auth().signIn(with: credential) {
      [weak self] authResult, err in
      guard let self = self else {return} 
      if let err = err {
        self.didLoginComplete?(false, err.localizedDescription)
        return
      }
      UserDefaults.set(appleIDCredential.user, forKey: .appleUserIdKey)
      LoginManager.shared.notifyLoginSuccess(type: .apple)
      self.didLoginComplete?(true, nil)
      
    }
  }
  
  /// Apple????????????
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    print("Apple??????????????? \(error.localizedDescription)")
    didLoginComplete?(nil, nil)
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
