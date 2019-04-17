//
//  ArrayExtension.swift
//  Calendar
//
//  Created by Bartłomiej Zabicki on 14/04/2019.
//  Copyright © 2019 Bartlomiej Zabicki. All rights reserved.
//

import Foundation

extension Array {
  public func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
