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
  @State private var signMode: SignModeSwitch.SignMode = .login
  
  var body: some View {
    ZStack {
      Color.yellow.ignoresSafeArea()
      
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
      .onTapGesture {
        UIApplication.shared.endEditing()
      }
    }
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
  
  @StateObject private var loginManager = LoginManager.shared
  
  @StateObject private var alertManager = AlertManager()
  
  // 使否顯示密碼
  @State private var visible = false
  
  private enum Field: Int, Hashable {
    case mail, pass
  }
  
  @FocusState private var focusedField: Field?
  
  var body: some View {
    
    VStack {
      
      // 登入輸入框
      VStack {
        
        // 輸入信箱
        HStack {
          
          Image(systemName: "envelope")
            .foregroundColor(.gray)
            .frame(width: 24, height: 24, alignment: .center)
          TextField("", text: $loginManager.inputMail)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: loginManager.inputMail.isEmpty, placeholder: {
              Text("Enter Email Address")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .mail)
            .textContentType(.emailAddress)
            .submitLabel(.next)
            .onSubmit {
              if focusedField == .mail {
                focusedField = .pass
              }
            }
        }
        .padding()
        .onTapGesture {
          focusedField = .mail
        }
        
        Divider()
        
        // 輸入密碼
        HStack {
          
          Image(systemName: "lock")
            .foregroundColor(.gray)
            .frame(width: 24, height: 24, alignment: .center)
          if visible {
            TextField("", text: $loginManager.inputPass)
              .accentColor(.gray)
              .foregroundColor(.gray)
              .placeholder(when: loginManager.inputPass.isEmpty, placeholder: {
                Text("Enter Password")
                  .foregroundColor(.gray.opacity(0.6))
              })
              .focused($focusedField, equals: .pass)
              .submitLabel(.done)
              .onSubmit {
                if focusedField == .pass {
                  didTapLogin()
                }
              }
          }else {
            SecureField("", text: $loginManager.inputPass)
              .accentColor(.gray)
              .foregroundColor(.gray)
              .placeholder(when: loginManager.inputPass.isEmpty, placeholder: {
                Text("Enter Password")
                  .foregroundColor(.gray.opacity(0.6))
              })
              .focused($focusedField, equals: .pass)
              .submitLabel(.done)
              .onSubmit {
                if focusedField == .pass {
                  didTapLogin()
                }
              }
          }
          
          Button {
            visible.toggle()
          } label: {
            Image(systemName: visible ? "eye.slash.fill" : "eye.fill")
              .foregroundColor(.gray)
          }
          
        }
        .padding()
        .onTapGesture {
          focusedField = .pass
        }
      }
      .background(.white)
      .cornerRadius(16)
      .clipped()
      .padding()
      .shadow(radius: 8)
      
      // 登入按鈕
      Button {
        didTapLogin()
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
  
  /// 觸發登入按鈕
  private func didTapLogin() {
    loginManager.mailLogin { err in
      if let err = err {
        alertManager.show(title: "Error", msg: err)
      }else {
        print("Login Success")
      }
    }
  }
}



// MARK: 註冊畫面
struct CNSignUpView: View {
  
  @StateObject private var loginManager = LoginManager.shared
  
  @StateObject private var alertManager = AlertManager()
  
  @State private var pass = ""
  @State private var repass = ""
  
  // 使否顯示密碼
  @State private var visible = false
  @State private var revisible = false
  
  @State private var isSuccessRegister = false
  
  private enum Field: Int, Hashable {
    case mail, pass, repass
  }
  
  @FocusState private var focusedField: Field?
  
  var body: some View {
    
    VStack {
      
      // 註冊輸入框
      VStack {
        
        // 輸入信箱
        HStack {
          
          Image(systemName: "envelope")
            .foregroundColor(.gray)
            .frame(width: 24, height: 24, alignment: .center)
          
          TextField("Enter Email Address", text: $loginManager.inputMail)
            .placeholder(when: loginManager.inputMail.isEmpty, placeholder: {
              Text("Enter Email Address")
                .foregroundColor(.gray.opacity(0.6))
            })
            .accentColor(.gray)
            .foregroundColor(.gray)
            .focused($focusedField, equals: .mail)
            .textContentType(.emailAddress)
            .submitLabel(.next)
            .onSubmit {
              if focusedField == .mail {
                focusedField = .pass
              }
            }
        }
        .padding()
        .onTapGesture {
          focusedField = .mail
        }
        Divider()
        
        // 輸入密碼
        HStack {
          
          Image(systemName: "lock")
            .frame(width: 24, height: 24, alignment: .center)
            .foregroundColor(.gray)
          if visible {
            TextField("Enter Password", text: $pass)
              .accentColor(.gray)
              .foregroundColor(.gray)
              .placeholder(when: pass.isEmpty, placeholder: {
                Text("Enter Password")
                  .foregroundColor(.gray.opacity(0.6))
              })
              .focused($focusedField, equals: .pass)
              .submitLabel(.next)
              .onSubmit {
                if focusedField == .pass {
                  focusedField = .repass
                }
              }
          }else {
            SecureField("Enter Password", text: $pass)
              .accentColor(.gray)
              .foregroundColor(.gray)
              .placeholder(when: pass.isEmpty, placeholder: {
                Text("Enter Password")
                  .foregroundColor(.gray.opacity(0.6))
              })
              .focused($focusedField, equals: .pass)
              .submitLabel(.next)
              .onSubmit {
                if focusedField == .pass {
                  focusedField = .repass
                }
              }
          }
          
          Button {
            visible.toggle()
          } label: {
            Image(systemName: visible ? "eye.slash.fill" : "eye.fill")
              .foregroundColor(.gray)
          }
          
        }
        .padding()
        .onTapGesture {
          focusedField = .pass
        }
        Divider()
        
        // 輸入再次密碼
        HStack {
          
          Image(systemName: "lock")
            .foregroundColor(.gray)
            .frame(width: 24, height: 24, alignment: .center)
          if revisible {
            TextField("Re-Enter Password", text: $repass)
              .accentColor(.gray)
              .foregroundColor(.gray)
              .placeholder(when: repass.isEmpty, placeholder: {
                Text("Re-Enter Password")
                  .foregroundColor(.gray.opacity(0.6))
              })
              .focused($focusedField, equals: .repass)
              .submitLabel(.done)
              .onSubmit {
                if focusedField == .repass {
                  didTapSignUp()
                }
              }
          }else {
            SecureField("Re-Enter Password", text: $repass)
              .accentColor(.gray)
              .foregroundColor(.gray)
              .placeholder(when: repass.isEmpty, placeholder: {
                Text("Re-Enter Password")
                  .foregroundColor(.gray.opacity(0.6))
              })
              .focused($focusedField, equals: .repass)
              .submitLabel(.done)
              .onSubmit {
                if focusedField == .repass {
                  didTapSignUp()
                }
              }
          }
          
          Button {
            revisible.toggle()
          } label: {
            Image(systemName: revisible ? "eye.slash.fill" : "eye.fill")
              .foregroundColor(.gray)
          }
          
        }
        .padding()
        .onTapGesture {
          focusedField = .repass
        }
      }
      .background(.white)
      .cornerRadius(16)
      .clipped()
      .padding()
      .shadow(radius: 8)
      
      // 註冊按鈕
      Button {
        didTapSignUp()
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
      
      if isSuccessRegister { // 如果成功註冊 詢問是否要立即登入
        Button("Later", role: .cancel) { alertManager.close() }
        
        Button("Login") {
          alertManager.close()
          didTapLogin()
        }
        
      }else {
        
        Button("OK", role: .cancel) { alertManager.close() }
        
      }
      
    } message: {
      Text(alertManager.message)
    }
    
    
  }
  
  // 觸發立即登入
  private func didTapLogin() {
    loginManager.mailLogin { err in
      if let err = err {
        alertManager.show(title: "Error", msg: err)
      }else {
        alertManager.close()
      }
    }
  }
  
  // 觸發註冊按鈕
  private func didTapSignUp() {
    loginManager.register(pass: pass, repass: repass) { isSuccess, msg in
      isSuccessRegister = isSuccess
      alertManager.show(title: isSuccess ? "Success" : "Error", msg: msg)
    }
  }
  
}

// MARK: 忘記密碼
struct ForgetPassword: View {
  
  @StateObject private var alertManager = AlertManager()
  
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
  
  @StateObject private var loginManager = LoginManager.shared
  
  @StateObject private var alertManager = AlertManager()
  
  private let fbIcon = "https://cdn-icons-png.flaticon.com/512/124/124010.png"
  
  private let googleIcon = "https://cdn-icons-png.flaticon.com/512/300/300221.png"
  
  private let appleIcon = "https://cdn-icons-png.flaticon.com/512/0/747.png"
  
  private let iconWidth: CGFloat = 54
  
  var body: some View {
    
    HStack(alignment: .center, spacing: 32) {
      
      Button {
        loginManager.facebookLogin { err in
          if let err = err {
            alertManager.show(title: "Error", msg: err)
          }else {
            print("FacebookLogin Success")
          }
        }
      } label: {
        iconImage(url: fbIcon)
      }
      .frame(width: iconWidth, height: iconWidth, alignment: .center)
      
      Button {
        loginManager.googleLogin { err in
          if let err = err {
            alertManager.show(title: "Error", msg: err)
          }else {
            print("GoogleLogin Success")
          }
        }
      } label: {
        iconImage(url: googleIcon)
      }
      .frame(width: iconWidth, height: iconWidth, alignment: .center)
      
      Button {
        loginManager.appleLogin()
        
      } label: {
        iconImage(url: appleIcon)
      }
      .frame(width: iconWidth, height: iconWidth, alignment: .center)
      
    }
    .padding(10)
    .alert(alertManager.title, isPresented: $alertManager.isShow) {
      Button("Ok", role: .cancel) {
        alertManager.close()
      }
    } message: {
      Text(alertManager.message)
    }
    .onAppear {
      setAppleLoginDidComplete()
    }
    
  }
  
  private func setAppleLoginDidComplete() {
    loginManager.didAppleLoginComplete = { err in
      if let err = err {
        alertManager.show(title: "Error", msg: err)
      }else {
        print("Apple Login Success")
      }
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

extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
