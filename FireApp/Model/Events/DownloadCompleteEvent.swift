//
//  DownloadCompleteEvent.swift
//  FireApp
//
//  Created by Devlomi on 9/12/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation

class DownloadCompleteEvent:NSObject {
    let id:String
  
    init(id:String) {
        self.id = id
    }
}
