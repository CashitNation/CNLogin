//
//  BlurEffect.swift
//  FirebaseTestDemo
//
//  Created by Ca$h on 2022/9/12.
//

import SwiftUI

struct Blur: UIViewRepresentable {
  var style: UIBlurEffect.Style = .systemMaterial
  func makeUIView(context: Context) -> UIVisualEffectView {
    return UIVisualEffectView(effect: UIBlurEffect(style: style))
  }
  func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    uiView.effect = UIBlurEffect(style: style)
  }
}
