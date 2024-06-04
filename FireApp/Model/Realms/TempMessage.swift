//
//  TempMessage.swift
//  FireApp
//
//  Created by Devlomi on 6/13/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class TempMessage: Object {

    override static func indexedProperties() -> [String] {
        return ["uid"]
    }
    
    override class func ignoredProperties() -> [String] {
        return ["status"]
    }

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
    @objc dynamic var timestamp:CLong = 0
    @objc dynamic var chatId = ""
    @objc dynamic private var messageStat = MessageState.PENDING.rawValue

    var messageState: MessageState {
        get {
            return MessageState(rawValue: messageStat)!
        }
        set {
            messageStat = newValue.rawValue
        }
    }

    @objc dynamic var localPath = ""

    @objc dynamic private var downloadUploadStat = DownloadUploadState.DEFAULT.rawValue

    var downloadUploadState: DownloadUploadState {
        get {
            return DownloadUploadState(rawValue: downloadUploadStat)!
        }
        set {
            downloadUploadStat = newValue.rawValue
        }
    }


    @objc dynamic var metatdata = ""
    @objc dynamic var voiceMessageSeen = false
    @objc dynamic var mediaDuration = ""
    @objc dynamic var thumb = ""
    @objc dynamic var isForwarded = false
    @objc dynamic var videoThumb = ""
    @objc dynamic var fileSize = ""
    @objc dynamic var contact: RealmContact?
    @objc dynamic var location: RealmLocation?
    @objc dynamic var isGroup = false
    @objc dynamic var isBroadcast = false
    @objc dynamic var isSeen = false
 
    @objc dynamic var quotedMessage: QuotedMessage?
    
    var broadcastUids = List<String>()
    @objc dynamic var encryptionType = EncryptionType.NONE
    
    var status:Status?

    static func mapMessageToTempMessage(message:Message) -> TempMessage{
        let tempMessage = TempMessage()
        tempMessage.messageId = message.messageId
        tempMessage.fromId = message.fromId
        tempMessage.fromPhone = message.fromPhone
        tempMessage.toId = message.toId
        tempMessage.typeEnum = message.typeEnum
        tempMessage.content = message.content
        tempMessage.timestamp = message.timestamp
        tempMessage.chatId = message.chatId
        tempMessage.messageState = message.messageState
        tempMessage.localPath = message.localPath
        tempMessage.downloadUploadState = message.downloadUploadState
        tempMessage.metatdata = message.metatdata
        tempMessage.voiceMessageSeen = message.voiceMessageSeen
        tempMessage.metatdata = message.mediaDuration
        tempMessage.thumb = message.thumb
        tempMessage.isForwarded = message.isForwarded
        tempMessage.videoThumb = message.videoThumb
        tempMessage.fileSize = message.fileSize
        tempMessage.contact = message.contact
        tempMessage.location = message.location
        tempMessage.isGroup = message.isGroup
        tempMessage.isBroadcast = message.isBroadcast
        tempMessage.isSeen = message.isSeen
        tempMessage.quotedMessage = message.quotedMessage
        tempMessage.broadcastUids = message.broadcastUids
        tempMessage.encryptionType = message.encryptionType
        tempMessage.status = message.status
        return tempMessage
    }
}
