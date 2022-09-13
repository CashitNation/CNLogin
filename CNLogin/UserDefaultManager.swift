//
//  UserDefaultManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import Foundation

extension UserDefaults {
  
  enum KeyType: String {
    // 是否登入
    case isLoginKey = "isLoginKey"
    // 記住帳號
    case rememberMailKey = "rememberMailKey"
    // 記住密碼
    case rememberPassKey = "rememberPassKey"
  }
  
  static func get(forKey key: KeyType) -> Any? {
    
    return UserDefaults.standard.value(forKey: key.rawValue)
  }
  
  static func set(_ value: Any, forKey key: KeyType) {
    UserDefaults.standard.set(value, forKey: key.rawValue)
  }
  
  static func remove(forKey key: KeyType) {
    UserDefaults.standard.removeObject(forKey: key.rawValue)
  }
  
}

extension NotificationCenter {
  
  enum KeyType: String {
    // 是否登入
    case isLoginKey = "isLoginKey"
  }
  
  static func add(forKey key: KeyType,
                  using block: ((Notification) -> Void)?) {
    NotificationCenter.default.addObserver(forName: NSNotification.Name(key.rawValue), object: nil, queue: .main) { notification in
      block?(notification)
    }
  }
  
  static func post(forKey key: KeyType) {
    NotificationCenter.default.post(name: NSNotification.Name(key.rawValue), object: nil)
  }
  
}
