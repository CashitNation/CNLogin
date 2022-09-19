//
//  CNLoginPageView.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/8.
//

import SwiftUI

// MARK: 登入或註冊頁
struct CNLoginPageView: View {
  
  private enum SignState {
    case signIn, signUp
    var btnText: String {
      switch self {
      case .signIn: return "Sign In"
      case .signUp: return "Sign Up"
      }
    }
  }
  
  // 當前頁面 登入/註冊 狀態
  @State private var signState: SignState = .signIn
  
  @StateObject private var loginManager = LoginManager.shared
  
  @StateObject private var alertManager = AlertManager()
  
  @StateObject private var fieldViewModel = FieldViewModel()
  
  @FocusState private var focusedField: FieldViewModel.SignField?
  
  var body: some View {
    ZStack {
      
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack {
          // Logo (url: 輸入Logo圖片網址)
          URLImage(url: "")
          
          Text("App Name").font(.largeTitle)
          
          if loginManager.isLoading {
            loadingView
          }else {
            // 登入/註冊
            signModeSwitch
            
            // 登入/註冊 帳密輸入框&確認
            switch signState {
            case .signIn: signInView
            case .signUp: signUpView
            }
            
            // 登入/註冊、忘記密碼、三方登入
            enterAreaView
          }
        }
        .padding()
      }
      .background(.green)
      .onTapGesture {
        UIApplication.shared.endEditing()
      }
      .alert(alertManager.title, isPresented: $alertManager.isShow) {
        
        if loginManager.isSuccessRegister { // 如果成功註冊 詢問是否要立即登入
          
          Button("Later", role: .cancel) {
            loginManager.isSuccessRegister = false
            alertManager.close()
          }
          
          Button("Login") {
            loginManager.isSuccessRegister = false
            alertManager.close()
            loginManager.isLoading = true
            loginManager.action(type: .mailLogin(mail: fieldViewModel.signMail, pass: fieldViewModel.signInPass))
          }
          
        }else {
          
          Button("OK", role: .cancel) { alertManager.close() }
          
        }
        
      } message: {
        Text(alertManager.message)
      }
      .onAppear {
        // 登入完成時觸發事件
        loginManager.needToShowAlert = { title, msg in
          DispatchQueue.main.async {
            self.loginManager.isLoading = false
            guard let title = title, let msg = msg else {return}
            self.alertManager.show(title: title, msg: msg)
          }
        }
        
        loginManager.action(type: .autoLogin)
      }
      
    }
  }
  
  // MARK: 讀取畫面
  private var loadingView: some View {
    
    VStack {
      ActivityIndicator(isAnimating: .constant(true), style: .large)
      Text("資料讀取中...")
    }
    .padding()
    .background(Blur(style: .systemThinMaterial))
    .cornerRadius(16)
  }
  
  // MARK: 登入/註冊切換按鈕
  private var signModeSwitch: some View {
    
    HStack {
      
      Button {
        
        withAnimation(.spring()) {
          signState = .signIn
        }
        
      } label: {
        Text("Sign In")
          .foregroundColor(signState == .signIn ? .black : .white)
          .padding(.vertical, 12)
          .frame(width: (UIScreen.main.bounds.width - 50) / 2)
      }
      .background(signState == .signIn ? .white : .clear)
      .clipShape(Capsule())
      
      Button {
        
        withAnimation(.spring()) {
          signState = .signUp
        }
        
      } label: {
        Text("Sign Up")
          .foregroundColor(signState == .signUp ? .black : .white)
          .padding(.vertical, 12)
          .frame(width: (UIScreen.main.bounds.width - 50) / 2)
      }
      .background(signState == .signUp ? .white : .clear)
      .clipShape(Capsule())
      
    }
    .background(Blur(style: .systemThinMaterial))
    .clipShape(Capsule())
    .shadow(radius: 8)
    
  }
  
  // MARK: 登入畫面
  private var signInView: some View {
    
    // 登入輸入框
    VStack {
      
      // 輸入信箱
      HStack {
        
        Image(systemName: "envelope")
          .foregroundColor(.gray)
          .frame(width: 24, height: 24, alignment: .center)
        
        TextField("", text: $fieldViewModel.signMail)
          .accentColor(.gray)
          .foregroundColor(.gray)
          .placeholder(when: fieldViewModel.signMail.isEmpty, placeholder: {
            Text("Enter Email Address")
              .foregroundColor(.gray.opacity(0.6))
          })
          .textContentType(.emailAddress)
          .focused($focusedField, equals: .inMail)
          .submitLabel(.next)
          .onSubmit {
            if focusedField == .inMail { focusedField = .inPass }
          }
      }
      .padding()
      .onTapGesture {
        focusedField = .inMail
      }
      
      Divider()
      
      // 輸入密碼
      HStack {
        
        Image(systemName: "lock")
          .foregroundColor(.gray)
          .frame(width: 24, height: 24, alignment: .center)
        if fieldViewModel.signInVisible {
          TextField("", text: $fieldViewModel.signInPass)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: fieldViewModel.signInPass.isEmpty, placeholder: {
              Text("Enter Password")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .inPass)
            .submitLabel(.done)
            .onSubmit {
              if focusedField == .inPass {
                loginManager.action(type: .mailLogin(mail: fieldViewModel.signMail, pass: fieldViewModel.signInPass))
              }
            }
        }else {
          SecureField("", text: $fieldViewModel.signInPass)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: fieldViewModel.signInPass.isEmpty, placeholder: {
              Text("Enter Password")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .inPass)
            .submitLabel(.done)
            .onSubmit {
              if focusedField == .inPass {
                loginManager.action(type: .mailLogin(mail: fieldViewModel.signMail, pass: fieldViewModel.signInPass))
              }
            }
        }
        
        Button {
          fieldViewModel.signInVisible.toggle()
        } label: {
          Image(systemName: fieldViewModel.signInVisible ? "eye.slash.fill" : "eye.fill")
            .foregroundColor(.gray)
        }
        
      }
      .padding()
      .onTapGesture {
        focusedField = .inPass
      }
      
    }
    .background(.white)
    .cornerRadius(16)
    .clipped()
    .padding()
    .shadow(radius: 8)
    
  }
  
  // MARK: 註冊畫面
  private var signUpView: some View {
    
    VStack {
      
      // 輸入信箱
      HStack {
        
        Image(systemName: "envelope")
          .foregroundColor(.gray)
          .frame(width: 24, height: 24, alignment: .center)
        
        TextField("Enter Email Address", text: $fieldViewModel.signMail)
          .placeholder(when: fieldViewModel.signMail.isEmpty, placeholder: {
            Text("Enter Email Address")
              .foregroundColor(.gray.opacity(0.6))
          })
          .textContentType(.emailAddress)
          .accentColor(.gray)
          .foregroundColor(.gray)
          .focused($focusedField, equals: .upMail)
          .submitLabel(.next)
          .onSubmit {
            if focusedField == .upMail {
              focusedField = .upPass
            }
          }
      }
      .padding()
      .onTapGesture {
        focusedField = .upMail
      }
      
      Divider()
      
      // 輸入密碼
      HStack {
        
        Image(systemName: "lock")
          .frame(width: 24, height: 24, alignment: .center)
          .foregroundColor(.gray)
        if fieldViewModel.signUpVisible {
          TextField("Enter Password", text: $fieldViewModel.signUpPass)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: fieldViewModel.signUpPass.isEmpty, placeholder: {
              Text("Enter Password")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .upPass)
            .submitLabel(.next)
            .onSubmit {
              if focusedField == .upPass {
                focusedField = .upRepass
              }
            }
        }else {
          SecureField("Enter Password", text: $fieldViewModel.signUpPass)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: fieldViewModel.signUpPass.isEmpty, placeholder: {
              Text("Enter Password")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .upPass)
            .submitLabel(.next)
            .onSubmit {
              if focusedField == .upPass {
                focusedField = .upRepass
              }
            }
        }
        
        Button {
          fieldViewModel.signUpVisible.toggle()
        } label: {
          Image(systemName: fieldViewModel.signUpVisible ? "eye.slash.fill" : "eye.fill")
            .foregroundColor(.gray)
        }
        
      }
      .padding()
      .onTapGesture {
        focusedField = .upPass
      }
      Divider()
      
      // 輸入再次密碼
      HStack {
        
        Image(systemName: "lock")
          .foregroundColor(.gray)
          .frame(width: 24, height: 24, alignment: .center)
        
        if fieldViewModel.signUprevisible {
          TextField("Re-Enter Password", text: $fieldViewModel.signUpRepass)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: fieldViewModel.signUpRepass.isEmpty, placeholder: {
              Text("Re-Enter Password")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .upRepass)
            .submitLabel(.done)
            .onSubmit {
              if focusedField == .upRepass {
                loginManager.action(type: .register(mail: fieldViewModel.signMail, pass: fieldViewModel.signUpPass, repass: fieldViewModel.signUpRepass))
              }
            }
        }else {
          SecureField("Re-Enter Password", text: $fieldViewModel.signUpRepass)
            .accentColor(.gray)
            .foregroundColor(.gray)
            .placeholder(when: fieldViewModel.signUpRepass.isEmpty, placeholder: {
              Text("Re-Enter Password")
                .foregroundColor(.gray.opacity(0.6))
            })
            .focused($focusedField, equals: .upRepass)
            .submitLabel(.done)
            .onSubmit {
              if focusedField == .upRepass {
                loginManager.action(type: .register(mail: fieldViewModel.signMail, pass: fieldViewModel.signUpPass, repass: fieldViewModel.signUpRepass))
              }
            }
        }
        
        Button {
          fieldViewModel.signUprevisible.toggle()
        } label: {
          Image(systemName: fieldViewModel.signUprevisible ? "eye.slash.fill" : "eye.fill")
            .foregroundColor(.gray)
        }
        
      }
      .padding()
      .onTapGesture {
        focusedField = .upRepass
      }
    }
    .background(.white)
    .cornerRadius(16)
    .clipped()
    .padding()
    .shadow(radius: 8)
    
  }
  
  private let iconWidth: CGFloat = 54
  
  private var enterAreaView: some View {
    
    VStack {
      
      HStack {
        // 登入/註冊按鈕
        Button {
          loginManager.isLoading = true
          switch signState {
          case .signIn:
            loginManager.action(type: .mailLogin(mail: fieldViewModel.signMail, pass: fieldViewModel.signInPass))
          case .signUp:
            fieldViewModel.signInPass = fieldViewModel.signUpPass
            loginManager.action(type: .register(mail: fieldViewModel.signMail,pass: fieldViewModel.signUpPass, repass: fieldViewModel.signUpRepass))
          }
        } label: {
          Text(signState.btnText)
            .padding()
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(radius: 8)
        
        // 忘記密碼
        Button {
          loginManager.isLoading = true
          loginManager.action(type: .resetPassword(mail: fieldViewModel.signMail))
        } label: {
          Text("Forget Password?")
            .foregroundColor(.white)
        }
      }
      
      HStack {
        Color.white
          .frame(width: 32, height: 1)
        Text("Or")
          .foregroundColor(.white)
        Color.white
          .frame(width: 32, height: 1)
      }
      
      HStack(alignment: .center, spacing: 32) {
        
        Button {
          loginManager.isLoading = true
          loginManager.action(type: .fbLogin)
        } label: {
          URLImage(url: LoginManager.LoginType.facebook.iconUrl)
            .background(.white)
            .clipShape(Circle())
            .shadow(radius: 8)
          
        }
        .frame(width: iconWidth, height: iconWidth, alignment: .center)
        
        Button {
          loginManager.isLoading = true
          loginManager.action(type: .googleLogin)
        } label: {
          URLImage(url: LoginManager.LoginType.google.iconUrl)
            .background(.white)
            .clipShape(Circle())
            .shadow(radius: 8)
        }
        .frame(width: iconWidth, height: iconWidth, alignment: .center)
        
        Button {
          loginManager.isLoading = true
          loginManager.action(type: .appleLogin)
          
        } label: {
          URLImage(url: LoginManager.LoginType.apple.iconUrl)
            .background(.white)
            .clipShape(Circle())
            .shadow(radius: 8)
        }
        .frame(width: iconWidth, height: iconWidth, alignment: .center)
        
      }
      
    }
    .padding()
    .background(Blur(style: .systemThinMaterial))
    .cornerRadius(16)
  }
  
}

extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
