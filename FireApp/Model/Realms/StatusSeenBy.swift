//
//  StatusSeenBy.swift
//  FireApp
//
//  Created by Devlomi on 3/17/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import RealmSwift

class StatusSeenBy: Object {
  

    @objc dynamic var user:User?
    @objc dynamic var seenAt:Int = 0
    
    convenience init(user:User,seenAt:Int) {
        self.init()
        self.user = user
        self.seenAt = seenAt
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let statusSeenBy = object as? StatusSeenBy{
            return statusSeenBy.user?.uid == self.user?.uid
        }
        return false
    }
}
