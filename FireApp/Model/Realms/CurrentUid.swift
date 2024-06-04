//
//  CurrentUid.swift
//  FireApp
//
//  Created by Devlomi on 12/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
class CurrentUid: Object {
    @objc dynamic var uid = ""
    
    override class func primaryKey() -> String? {
        return "uid"
    }
    
    convenience init(uid:String) {
        self.init()
        self.uid = uid
    }
}
