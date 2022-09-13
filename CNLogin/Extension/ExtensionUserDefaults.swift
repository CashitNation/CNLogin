//
//  ExtensionUserDefaults.swift
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