//
//  FBLoginHelper.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/14.
//

import Firebase
import FacebookLogin
import FBSDKLoginKit
import FBSDKShareKit

class FBLoginHelper: NSObject {
  
  enum FBLoginMode {
    case normal
    case share
    
    var permissions: [String] {
      switch self {
      case .normal:
        return ["email", "public_profile"]
      case .share:
        return ["public_profile"]
      }
    }
  }
  
  private lazy var fbLoginManager = {
    return FBSDKLoginKit.LoginManager()
  }()
  
  var didLoginComplete: ((_ isSuccess: Bool?, _ msg: String?)->Void)?
  
  func facebookLogin(isAutoLogin: Bool = false) {
    fbLoginManager.logIn(permissions: FBLoginMode.normal.permissions, from: nil) {
      [weak self] result, err in
      guard let self = self else {return}
      
      if let err = err {
        self.didLoginComplete?(false, err.localizedDescription)
        return
      }
      
      if !isAutoLogin, let result = result, result.isCancelled {
        self.didLoginComplete?(nil, nil)
        return
      }
      
      self.loginFBSuccess { err in
        if let err = err {
          self.didLoginComplete?(false, err)
          return
        }
        
        LoginManager.shared.notifyLoginSuccess(type: .facebook)
        self.didLoginComplete?(true, nil)
        
      }
    }
    
  }
  
  private func loginFBSuccess(errMsg: @escaping ((_ err: String?)->Void)) {
    guard AccessToken.current?.hasGranted(.email) == true else {
      // 沒有權限
      print("You don't have permission, please try again")
      return
    }
    let parameters = ["fields" : "id,name,email,gender,birthday,picture.type(large)"]
    GraphRequest(graphPath: "me", parameters: parameters).start { connecting, result, error in
      
      if let error = error {
        errMsg(error.localizedDescription)
        return
      }
      
      // 擷取用戶的access token，並通過調用將其轉換為Firebase的憑證
      guard let current = AccessToken.current else {
        errMsg("Empty FB Token")
        return
      }
      
      Profile.loadCurrentProfile { profile, error in
        guard let profile = profile else { return }
        print("\(profile.userID)\n\(profile.name ?? "")\n\(profile.email ?? "")\n\(String(describing: profile.imageURL(forMode: .square, size: CGSize(width: 300, height: 300))))")
      }
      
      let credential = FacebookAuthProvider.credential(withAccessToken: current.tokenString)
      
      Auth.auth().signIn(with: credential) { authResult, err in
        if let err = err {
          errMsg(err.localizedDescription)
          return
        }
        
        errMsg(nil)
        
      }
      
    }
  }
  
  func facebookLogout() {
      fbLoginManager.logOut()
  }
  
}
