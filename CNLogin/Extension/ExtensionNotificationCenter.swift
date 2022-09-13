//
//  ExtensionNotificationCenter.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import Foundation

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
