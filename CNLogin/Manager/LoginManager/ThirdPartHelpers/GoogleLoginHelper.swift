//
//  GoogleLoginHelper.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/14.
//

import Firebase
import GoogleSignIn

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
      
      guard let user = user, let idToken = user.authentication.idToken else {
        print("Can't find your google user ID")
        return
      }
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.authentication.accessToken)
      
      Auth.auth().signIn(with: credential) { (_, err) in
        if let err = err {
          alert(err.localizedDescription)
          return
        }
        // 在此取得使用者資訊 Google user?.profile
//        LoginManager.shared.googleProfile = user?.profile
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
      
      guard let user = user, let idToken = user.authentication.idToken else {
        print("Can't find your google user ID")
        return
      }
      
      let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.authentication.accessToken)
      
      Auth.auth().signIn(with: credential) { authResult, err in
        if let err = err {
          alert(err.localizedDescription)
          return
        }
        // 在此取得使用者資訊 Google user?.profile
//        LoginManager.shared.googleProfile = user?.profile
        LoginManager.shared.notifyLoginSuccess(type: .google)
        alert(nil)
        
      }
    }
  }
  
  func googleLogout() {
      GIDSignIn.sharedInstance.signOut()
  }
}
