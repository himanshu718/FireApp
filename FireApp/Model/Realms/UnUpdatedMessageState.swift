//
//  UnUpdatedMessageState.swift
//  FireApp
//
//  Created by Devlomi on 12/7/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class UnUpdatedMessageState: Object {
    
    override static func primaryKey() -> String? {
         return "messageId"
     }
    

    @objc dynamic var  messageId = ""
    @objc dynamic var  myUid = ""
     //state to update (received,read)
    @objc dynamic var statToBeUpdated = 0
    
    @objc dynamic var chatId = ""
    
    convenience init(messageId:String,myUid:String,chatId:String,statToBeUpdated:MessageState) {
        self.init()
        self.messageId = messageId
        self.myUid = myUid
        self.chatId = chatId
        self.statToBeUpdated = statToBeUpdated.rawValue
    }
}
