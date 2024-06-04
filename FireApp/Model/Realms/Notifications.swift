//
//  Notifications.swift
//  FireApp
//
//  Created by Devlomi on 2/20/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import RealmSwift
class Notifications: Object {
    @objc dynamic var chatId:String = ""
    @objc dynamic var notificationId:String = ""
    @objc dynamic var messageId:String = ""
    
   
    override class func indexedProperties() -> [String] {
        return ["chatId"]
    }
    
    convenience init(chatId:String,notificationId:String,messageId:String = "") {
        self.init()
        self.chatId = chatId
        self.notificationId = notificationId
        self.messageId = messageId
    }
}

