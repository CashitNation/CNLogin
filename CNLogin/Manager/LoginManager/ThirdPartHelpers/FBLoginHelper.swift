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
  
  var didLoginComplete: ((_ isSuccess: Bool, _ msg: String?)->Void)?
  
  func facebookLogin() {
    fbLoginManager.logIn(permissions: FBLoginMode.normal.permissions, from: nil) {
      [weak self] result, err in
      guard let self = self else {return}
      
      if let err = err {
        self.didLoginComplete?(false, err.localizedDescription)
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
      
      // 在此取得使用者資訊 result
//      guard let result = result as? [String : Any] else { return }
//      let name = result["name"] as? String
//      let email = result["email"] as? String ?? ""
//      let token = AccessToken.current?.tokenString
//      let picture = result["picture"] as? [String : Any]
//      let data = picture?["data"] as? [String : Any]
//      let urlString = data?["url"] as? String ?? ""
//      guard let token = token, token != "" else {
//        // "無法取得認證資料，請重新登入，或是換組帳號嘗試登入"
//        alert("You don't have permission, please try again")
//        return
//      }
//      var userName = email
//      if let name = name, name != "" {
//        userName = name
//      }
//      let fbAppId = Bundle.main.infoDictionary?["FacebookAppID"] as? String ?? "197209001129520"
//      let memberData: [String : String] = [
//        "name": userName,
//        "email": email,
//        "avatar": urlString,
//        "auth_token": token,
//        "app_id": fbAppId
//      ]
      
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
//      self.delegate?.facbookLoginCompleteSuccess(memberData)
      // 登入拿到資料後就登出FB
//      self.facebookLogout()
    }
  }
  
  func facebookLogout() {
      fbLoginManager.logOut()
  }
  
}
