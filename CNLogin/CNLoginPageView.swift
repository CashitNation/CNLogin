//
//  CNLoginPageView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI

struct CNLoginPageView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      CNLoginPageView()
        .preferredColorScheme(.light)
      CNLoginPageView()
        .preferredColorScheme(.dark)
    }
  }
}

// MARK: 登入或註冊頁
struct CNLoginPageView: View {
  
  // 當前頁面 登入/註冊 狀態
  @State var signMode: SignModeSwitch.SignMode = .login
  
  var body: some View {
    
    ZStack {
      
      ScrollView(.vertical, showsIndicators: false) {
        VStack {
          
          // Logo圖檔 imgUrl: 輸入Logo圖片網址
          CNLogoImage(imgUrl: "")
          
          // 登入/註冊
          SignModeSwitch(signMode: $signMode)
          
          // 登入/註冊 帳密輸入框&確認
          containedSignModeView()
          
          // 忘記密碼/或
          ForgetPassword()
          
          // 三方登入
          ThirdPartyLogin()
          
        }
      }
      .padding()
      
    }
    .background(.green)
    
  }
  /// 取得登入/註冊畫面 帳密輸入框&確認
  private func containedSignModeView() -> AnyView {
    switch signMode {
    case .login: return AnyView(CNLoginView())
    case .signUp: return AnyView(CNSignUpView())
    }
  }
  
}

// MARK: Logo圖檔
struct CNLogoImage: View {
  
  var imgUrl: String = ""
  
  var body: some View {
    
    AsyncImage(
      url: URL(string: imgUrl),
      content: { image in
        image.resizable()
      },
      placeholder: {
        if !imgUrl.isEmpty {
          ActivityIndicator(isAnimating: .constant(true), style: .large)
        }else {
          ZStack {
            Image(systemName: "circle").resizable()
              .aspectRatio(contentMode: .fit)
              .scaledToFit()
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .padding()
            Text("Logo_Image")
          }
        }
      })
    .aspectRatio(contentMode: .fit)
    
  }
  
}

// MARK: 登入/註冊切換按鈕
struct SignModeSwitch: View {
  
  enum SignMode {
    case login
    case signUp
  }
  
  @Binding var signMode: SignMode
  
  var body: some View {
    
    HStack {
      
      Button {
        
        withAnimation(.spring()) {
          signMode = .login
        }
        
      } label: {
        Text("Sign In")
          .foregroundColor(signMode == .login ? .black : .white)
          .padding(.vertical, 8)
          .frame(width: (UIScreen.main.bounds.width - 50) / 2)
      }
      .background(signMode == .login ? .white : .clear)
      .clipShape(Capsule())
      
      Button {
        
        withAnimation(.spring()) {
          signMode = .signUp
        }
        
      } label: {
        Text("Sign Up")
          .foregroundColor(signMode == .signUp ? .black : .white)
          .padding(.vertical, 8)
          .frame(width: (UIScreen.main.bounds.width - 50) / 2)
      }
      .background(signMode == .signUp ? .white : .clear)
      .clipShape(Capsule())
      
    }
    .background(.black.opacity(0.3))
    .clipShape(Capsule())
    .shadow(radius: 8)
    
  }
  
}

// MARK: 登入畫面
struct CNLoginView: View {
  
  @ObservedObject private var loginManager = LoginManager.shared
  
  @ObservedObject private var alertManager = AlertManager()
  
  // 使否顯示密碼
  @State var visible = false
  
  var body: some View {
    
    VStack {
      
      VStack {
        
        HStack {
          
          Image(systemName: "envelope")
          
          TextField("Enter Email Address", text: $loginManager.mail)
            .accentColor(.gray)
        }
        .padding()
        
        Divider()
        
        HStack {
          
          Image(systemName: "lock")
          
          if visible {
            TextField("Enter Password", text: $loginManager.pass)
            
              .accentColor(.gray)
          }else {
            SecureField("Enter Password", text: $loginManager.pass)
            
              .accentColor(.gray)
          }
          
          Button {
            visible.toggle()
          } label: {
            Image(systemName: visible ? "eye.slash.fill" : "eye.fill")
              .foregroundColor(.gray)
          }
          
        }
        .padding()
        
      }
      .background(.white)
      .cornerRadius(16)
      .clipped()
      .padding()
      .shadow(radius: 8)
      
      Button {
        loginManager.login { err in
          if let err = err {
            alertManager.show(title: "Error", msg: err)
          }else {
            print("Login Success")
          }
        }
      } label: {
        Text("Log In")
          .padding()
      }
      .background(.white)
      .cornerRadius(16)
      .shadow(radius: 8)
      
    }
    .alert(alertManager.title, isPresented: $alertManager.isShow) {
      Button("OK", role: .cancel) {
        alertManager.close()
      }
    } message: {
      Text(alertManager.message)
    }
    
    
  }
  
}



// MARK: 註冊畫面
struct CNSignUpView: View {
  
  @ObservedObject private var loginManager = LoginManager.shared
  
  @ObservedObject private var alertManager = AlertManager()
  
  @State private var pass = ""
  @State private var repass = ""
  
  // 使否顯示密碼
  @State private var visible = false
  @State private var revisible = false
  
  var body: some View {
    
    VStack {
      
      VStack {
        
        HStack {
          
          Image(systemName: "envelope")
          
          TextField("Enter Email Address", text: $loginManager.mail)
            .accentColor(.gray)
        }
        .padding()
        
        Divider()
        
        HStack {
          
          Image(systemName: "lock")
          
          if visible {
            TextField("Enter Password", text: $pass)
            
              .accentColor(.gray)
          }else {
            SecureField("Enter Password", text: $pass)
            
              .accentColor(.gray)
          }
          
          Button {
            visible.toggle()
          } label: {
            Image(systemName: visible ? "eye.slash.fill" : "eye.fill")
              .foregroundColor(.gray)
          }
          
        }
        .padding()
        
        Divider()
        
        HStack {
          
          Image(systemName: "lock")
          
          if revisible {
            TextField("Re-Enter Password", text: $repass)
              .accentColor(.gray)
          }else {
            SecureField("Re-Enter Password", text: $repass)
              .accentColor(.gray)
          }
          
          Button {
            revisible.toggle()
          } label: {
            Image(systemName: revisible ? "eye.slash.fill" : "eye.fill")
              .foregroundColor(.gray)
          }
          
        }
        .padding()
        
      }
      .background(.white)
      .cornerRadius(16)
      .clipped()
      .padding()
      .shadow(radius: 8)
      
      Button {
        loginManager.register(pass: pass, repass: repass) { title, msg in
          alertManager.show(title: title, msg: msg)
        }
      } label: {
        Text("Sign Up")
          .padding()
      }
      .background(.white)
      .cornerRadius(16)
      .shadow(radius: 8)
      
    }
    .alert(alertManager.title,
           isPresented: $alertManager.isShow) {
      Button("OK", role: .cancel) {
        alertManager.close()
      }
    } message: {
      Text(alertManager.message)
    }
    
    
  }
}

// MARK: 忘記密碼
struct ForgetPassword: View {
  
  @ObservedObject private var alertManager = AlertManager()
  
  var body: some View {
    
    VStack {
      
      Button {
        LoginManager.shared.resetPassword() { title, msg in
          alertManager.show(title: title, msg: msg)
        }
      } label: {
        Text("Forget Password?")
          .foregroundColor(.white)
      }
      
      HStack {
        Color.white
          .frame(width: 32, height: 1)
        Text("Or")
          .foregroundColor(.white)
        Color.white
          .frame(width: 32, height: 1)
      }
      
    }
    .padding()
    .background(.black.opacity(0.3))
    .cornerRadius(16)
    .alert(alertManager.title, isPresented: $alertManager.isShow) {
      
    } message: {
      Text(alertManager.message)
    }
    
    
    
  }
  
}

// MARK: 三方登入
struct ThirdPartyLogin: View {
  
  private let fbIcon = "https://cdn-icons-png.flaticon.com/512/124/124010.png"
  
  private let googleIcon = "https://cdn-icons-png.flaticon.com/512/300/300221.png"
  
  private let appleIcon = "https://cdn-icons-png.flaticon.com/512/0/747.png"
  
  private let iconWidth: CGFloat = 54
  
  var body: some View {
    HStack(alignment: .center, spacing: 32) {
      
      Button {
        print("FB Login")
      } label: {
        iconImage(url: fbIcon)
      }
      .frame(width: iconWidth, height: iconWidth, alignment: .center)
      
      Button {
        print("Google Login")
      } label: {
        iconImage(url: googleIcon)
      }
      .frame(width: iconWidth, height: iconWidth, alignment: .center)
      
      Button {
        print("Apple Login")
      } label: {
        iconImage(url: appleIcon)
      }
      .frame(width: iconWidth, height: iconWidth, alignment: .center)
      
    }
    
  }
  
  private func iconImage(url: String) -> AnyView {
    let img = AsyncImage(
      url: URL(string: url),
      content: { image in
        image.resizable()
      },
      placeholder: {
        ActivityIndicator(isAnimating: .constant(true), style: .medium)
      })
      .padding()
      .aspectRatio(contentMode: .fit)
      .background(.white)
      .clipShape(Circle())
      .shadow(radius: 8)
    return AnyView(img)
  }
  
}
