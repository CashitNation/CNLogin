//
//  KeychainHelper.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/14.
//

import Foundation
import KeychainAccess

class KeychainHelper {
    
    init() {}
    
    enum Keys: String {
        case email = "Email"
        case password = "Password"
        case loginType = "LoginType"
        case appleUserIdentifier = "AppleUserIdentifier"
        case appleUserName = "AppleUserName"
    }
    
    /// 用於設定keychain的伺服器欄位(辨識用，不會連線)
    private let server = Bundle.main.bundleIdentifier ?? "com.CashitNation.CNLogin"
    
    /// 設定資料到keychain裡
    ///
    /// - Parameters:
    ///   - key: 辨識用key
    ///   - value: 資料
    func setKey(_ key: String, to value: String) {
        let keychain = Keychain(server: server, protocolType: .https)
        keychain[key] = value
    }
    
    /// 從keychain裡拿資料
    ///
    /// - Parameter key: 辨識用key
    /// - Returns: 資料，取不到回傳nil
    func getValue(_ key: String) -> String? {
        let keychain = Keychain(server: server, protocolType: .https)
        let keychainData = try? keychain.get(key)
        
        guard let optionalData = keychainData else {
            return nil
        }
        return optionalData
    }
    
    /// 從keychain移除資料
    ///
    /// - Parameter key: 辨識用key
    func removeKey(_ key: String) {
        let keychain = Keychain(server: server, protocolType: .https)
        keychain[key] = nil
    }
}
