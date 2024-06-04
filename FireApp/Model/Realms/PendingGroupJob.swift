//
//  File.swift
//  FireApp
//
//  Created by Devlomi on 2/22/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class PendingGroupJob: Object {
    
    @objc dynamic var groupId = ""
    @objc dynamic private var eventType = GroupEventType.Default.rawValue

        var type: GroupEventType {
        get {
            return GroupEventType(rawValue: eventType)!
        }
        set {
            eventType = newValue.rawValue
        }

    }
    @objc dynamic var groupEvent: GroupEvent?
    override class func primaryKey() -> String? {
        return "groupId"
    }
    
    
    convenience init(groupId:String,type:GroupEventType,event:GroupEvent?) {
        self.init()
        self.groupId = groupId
        self.type = type
        self.groupEvent = event
    }
}
