//
//  ExtensionUIApplication.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/19.
//

import UIKit

extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
