//
//  ProgressEventData.swift
//  FireApp
//
//  Created by Devlomi on 9/8/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class ProgressEventData:NSObject {
    let id:String
    let progress:Float
    init(id:String,progress:Float) {
        self.id = id
        self.progress = progress
    }
}
