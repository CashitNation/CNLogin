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
  
  func facebookLogin(alert: @escaping ((_ err: String?)->Void)) {
    loginAndRequestPermissions(mode: .normal) { [weak self] in
      guard let self = self else {return}
      self.loginFBSuccess(alert: alert)
    } errorHandler: { error in
      alert(error.localizedDescription)
    }
  }
  
  private func loginAndRequestPermissions(mode: FBLoginMode,
                                          successHandler: @escaping () -> Void,
                                          errorHandler: ((Error)->Void)?) {
    
    fbLoginManager.logIn(permissions: mode.permissions, from: nil) { result, error  in
      if let error = error {
        errorHandler?(error)
        return
      }
      
      if let _ = result {
//        result.token
//        if result.isCancelled {
//            print("Cancel Facebook Login")
//        }else {
          successHandler()
//        }
      }
    }
  }
  
  private func loginFBSuccess(alert: @escaping ((_ err: String?)->Void)) {
    guard AccessToken.current?.hasGranted(.email) == true else {
      // 沒有權限
      print("You don't have permission, please try again")
      return
    }
    let parameters = ["fields" : "id,name,email,gender,birthday,picture.type(large)"]
    GraphRequest(graphPath: "me", parameters: parameters).start { connecting, result, error in
      
      if let error = error {
        alert(error.localizedDescription)
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
        alert("Empty FB Token")
        return
      }
      
      Profile.loadCurrentProfile { profile, error in
        guard let profile = profile else { return }
        print("\(profile.userID)\n\(profile.name ?? "")\n\(profile.email ?? "")\n\(String(describing: profile.imageURL(forMode: .square, size: CGSize(width: 300, height: 300))))")
      }
      
      let credential = FacebookAuthProvider.credential(withAccessToken: current.tokenString)
      
      Auth.auth().signIn(with: credential) { authResult, err in
        if let err = err {
          alert(err.localizedDescription)
          return
        }
        
        LoginManager.shared.notifyLoginSuccess(type: .facebook)
        alert(nil)
        
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
