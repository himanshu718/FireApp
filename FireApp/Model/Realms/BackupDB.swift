//
//  BackupDB.swift
//  FireApp
//
//  Created by Devlomi on 3/29/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class BackupDB: Object {
    @objc dynamic var pk = 1
    
    override class func primaryKey() -> String? {
        return "pk"
    }
    
    @objc dynamic var encryptedPassword:String = ""
    @objc dynamic var password:String = ""
    @objc dynamic var backupTime:Int = 0
    @objc dynamic var fileSize:Int = 0
    var mediaTypes = List<Int>()
    var paths = List<String>()
    var localFiles = List<String>()
    var successTypes = List<Int>()
    @objc dynamic var downloadedBytes = 0
    @objc dynamic var isInProgress = false
    
}
