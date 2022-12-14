//
//  GoogleLoginHelper.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/14.
//

import Firebase
import GoogleSignIn

class GoogleLoginHelper: NSObject {
  
  var didLoginComplete: ((_ isSuccess: Bool?, _ msg: String?)->Void)?
  
  func googleAutoLogin() {
    
    guard GIDSignIn.sharedInstance.hasPreviousSignIn() else {
      didLoginComplete?(false, "hasNotPreviousSignIn")
      return
    }
    
    GIDSignIn.sharedInstance.restorePreviousSignIn {
      
      [weak self] user, err in
      guard let self = self else {return}
      
      if let err = err {
        print(err.localizedDescription)
        self.didLoginComplete?(nil, nil)
        return
      }
      
      guard let user = user, let idToken = user.authentication.idToken else {
        print("Can't find your google user ID")
        self.didLoginComplete?(nil, nil)
        return
      }
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.authentication.accessToken)
      
      Auth.auth().signIn(with: credential) { (_, err) in
        if let err = err {
          self.didLoginComplete?(false, err.localizedDescription)
          return
        }
        
        LoginManager.shared.notifyLoginSuccess(type: .google)
        self.didLoginComplete?(true, nil)
      }
      
    }
    
  }
  
  func googleLogin() {
    
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      self.didLoginComplete?(nil, nil)
      return
    }
    let configuration = GIDConfiguration(clientID: clientID)
    
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
      self.didLoginComplete?(nil, nil)
      return
    }
    
    GIDSignIn.sharedInstance.signIn(with: configuration, presenting: rootViewController) {
      [weak self] user, err in
      guard let self = self else {return} 
      if let err = err {
        print(err.localizedDescription)
        self.didLoginComplete?(nil, nil)
        return
      }
      
      guard let user = user, let idToken = user.authentication.idToken else {
        print("Can't find your google user ID")
        self.didLoginComplete?(nil, nil)
        return
      }
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.authentication.accessToken)
      
      Auth.auth().signIn(with: credential) { authResult, err in
        if let err = err {
          self.didLoginComplete?(false, err.localizedDescription)
          return
        }
        LoginManager.shared.notifyLoginSuccess(type: .google)
        self.didLoginComplete?(true, nil)
      }
    }
  }
  
  func googleLogout() {
      GIDSignIn.sharedInstance.signOut()
  }
}
