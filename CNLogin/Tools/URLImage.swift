//
//  URLImage.swift
//  FirebaseTestDemo
//
//  Created by Ca$h on 2022/9/12.
//

import SwiftUI
import CachedAsyncImage

struct URLImage: View {
  
  @State var url: String
  
  var body: some View {
    CachedAsyncImage(
      url: URL(string: url),
      content: { image in
        image.resizable()
      },
      placeholder: {
        if URL(string: url) != nil {
          ActivityIndicator(isAnimating: .constant(true), style: .large)
        }else {
          Image(systemName: "photo")
            .resizable()
            .tint(.gray)
        }
      })
    .aspectRatio(contentMode: .fit)
    .scaledToFit()
    .frame(maxWidth: .infinity, alignment: .center)
    .padding()
  }
  
}

// URLCache+imageCache.swift

extension URLCache {
    
    static let imageCache = URLCache(memoryCapacity: 512*1000*1000, diskCapacity: 10*1000*1000*1000)
  
}
