//
//  Broadcast.swift
//  FireApp
//
//  Created by Devlomi on 5/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class Broadcast: Object {
    override static func primaryKey() -> String? {
        return "broadcastId"
    }
    
    @objc dynamic var broadcastId=""
    @objc dynamic var createdByNumber=""
    @objc dynamic var timestamp:CLong = 0
    var users = List<User>()
    

}
