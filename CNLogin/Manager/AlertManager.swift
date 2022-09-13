//
//  AlertManager.swift
//  CNLogin
//
//  Created by Ca$h on 2022/9/13.
//

import SwiftUI
// MARK: 彈窗經理
class AlertManager: ObservableObject {
  
  @Published var isShow: Bool = false
  
  var title: String = ""
  
  var message: String = ""
  
  func show(title: String = "", msg: String = "") {
    self.title = title
    self.message = msg
    self.isShow = true
  }
  
  func close() {
    self.title = ""
    self.message = ""
    self.isShow = false
  }
  
}
