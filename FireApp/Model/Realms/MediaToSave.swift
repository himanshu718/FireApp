//
//  MediaToSave.swift
//  FireApp
//
//  Created by Devlomi on 3/4/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import RealmSwift
class MediaToSave: Object {
    @objc dynamic var id:String = ""
    @objc dynamic var path:String = ""
    @objc dynamic var isVideo:Bool = false
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id:String,path:String,isVideo:Bool) {
        self.init()
        self.id = id
        self.path = path
        self.isVideo = isVideo
    }
}
