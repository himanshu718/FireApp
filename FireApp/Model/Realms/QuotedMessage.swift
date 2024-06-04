//
//  QuotedMessage.swift
//  FireApp
//
//  Created by Devlomi on 5/21/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class QuotedMessage: Object {

    @objc dynamic var messageId = ""
    @objc dynamic var fromId = ""
    @objc dynamic var fromPhone = ""
    @objc dynamic var toId = ""
    @objc dynamic private var type = MessageType.SENT_TEXT.rawValue

    var typeEnum: MessageType {
        get {
            return MessageType(rawValue: type)!
        }
        set {
            type = newValue.rawValue
        }
    }
    @objc dynamic var content = ""
    @objc dynamic var metatdata = ""
    @objc dynamic var mediaDuration = ""
    @objc dynamic var thumb = ""
    @objc dynamic var fileSize = ""
    @objc dynamic var localPath = ""
    @objc dynamic var contact: RealmContact?
    @objc dynamic var location: RealmLocation?
    @objc dynamic var isBroadcast = false
    @objc dynamic var status:Status?
    @objc dynamic var encryptionType = EncryptionType.NONE
    

    static func messageToQuotedMessage(_ message: Message) -> QuotedMessage {
        let quotedMessage = QuotedMessage()
        quotedMessage.contact = message.contact
        quotedMessage.content = message.content
        quotedMessage.fileSize = message.fileSize
        quotedMessage.fromId = message.fromId
        quotedMessage.fromPhone = message.fromPhone
        quotedMessage.location = message.location
        quotedMessage.mediaDuration = message.mediaDuration
        quotedMessage.messageId = message.messageId
        quotedMessage.thumb = message.thumb
        quotedMessage.typeEnum = message.typeEnum
        quotedMessage.toId = message.toId
        quotedMessage.metatdata = message.metatdata
        quotedMessage.isBroadcast = message.isBroadcast
        quotedMessage.status = message.status
        if message.typeEnum.isStickerType(){
            quotedMessage.localPath = message.localPath
        }
        
        quotedMessage.encryptionType = message.encryptionType
        
        return quotedMessage
    }

    static func quotedMessageToMessage(_ quotedMessage: QuotedMessage) -> Message {
        let message = Message()
        message.contact = quotedMessage.contact
        message.content = quotedMessage.content
        message.fileSize = quotedMessage.fileSize
        message.fromId = quotedMessage.fromId
        message.fromPhone = quotedMessage.fromPhone
        message.location = quotedMessage.location
        message.mediaDuration = quotedMessage.mediaDuration
        message.messageId = quotedMessage.messageId
        message.thumb = quotedMessage.thumb
        message.typeEnum = quotedMessage.typeEnum
        message.toId = quotedMessage.toId
        message.metatdata = quotedMessage.metatdata
        message.isBroadcast = quotedMessage.isBroadcast
        message.status = quotedMessage.status
        message.encryptionType = quotedMessage.encryptionType
        return message
    }
}

extension QuotedMessage{
    func toMessage() ->Message{
        return QuotedMessage.quotedMessageToMessage(self)
    }
}


