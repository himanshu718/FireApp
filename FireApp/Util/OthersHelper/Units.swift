//
//  Units.swift
//  FireApp
//
//  Created by Devlomi on 3/25/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
public struct Units {
  
  public let bytes: Int64
  
  public var kilobytes: Double {
    return Double(bytes) / 1_024
  }
  
  public var megabytes: Double {
    return kilobytes / 1_024
  }
  
  public var gigabytes: Double {
    return megabytes / 1_024
  }
  
  public init(bytes: Int64) {
    self.bytes = bytes
  }
}
