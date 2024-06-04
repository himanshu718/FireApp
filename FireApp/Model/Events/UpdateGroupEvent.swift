//
//  UpdateGroupEvent.swift
//  FireApp
//
//  Created by Devlomi on 12/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class UpdateGroupEvent: NSObject {
    let groupId:String
    init(groupId:String) {
        self.groupId = groupId
    }
}
