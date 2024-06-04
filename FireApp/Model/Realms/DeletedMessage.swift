//
//  DeletedMessage.swift
//  FireApp
//
//  Created by Devlomi on 12/10/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import RealmSwift
class DeletedMessage: Object {
    override static func primaryKey() -> String? {
        return "messageId"
    }

    @objc dynamic var messageId: String = ""

    convenience init(messageId: String) {
        self.init()
        self.messageId = messageId
    }

}
