//
//  ActivityIndicator.swift
//  LandmarksTestDemo
//
//  Created by Ca$h on 2022/8/31.
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
  
  @Binding var isAnimating: Bool
  
  let style: UIActivityIndicatorView.Style
  
  var tintColor: UIColor = .lightGray
  
  func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
    let view = UIActivityIndicatorView(style: style)
    view.color = tintColor
    view.sizeToFit()
    return view
  }
  
  func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
    isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
  }
}
