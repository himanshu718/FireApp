//
//  ScheduledMessage.swift
//  FireApp
//
//  Created by Devlomi on 4/22/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseDatabase

class ScheduledMessage: Object {

    @objc dynamic var messageId = ""
    @objc dynamic var fromId = ""
    @objc dynamic var fromPhone = ""
    @objc dynamic var toId = ""
    @objc dynamic var chatId = ""
    @objc dynamic private var type = MessageType.SENT_TEXT.rawValue

    override class func primaryKey() -> String? {
        return "messageId"
    }
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
    @objc dynamic var isGroup = false
    var broadcastUids = List<String>()
    @objc dynamic var encryptionType = EncryptionType.NONE
    


    @objc dynamic private var downloadUploadStat = DownloadUploadState.DEFAULT.rawValue


    var downloadUploadState: DownloadUploadState {
        get {
            return DownloadUploadState(rawValue: downloadUploadStat)!
        }
        set {
            downloadUploadStat = newValue.rawValue
        }
    }


    @objc dynamic var scheduledAt: CLong = 0
    @objc dynamic var timeToExecute: CLong = 0

    @objc dynamic private var state = ScheduledMessageState.unknown.rawValue

    var status: ScheduledMessageState {
        get {
            return ScheduledMessageState(rawValue: state)!
        }
        set {
            state = newValue.rawValue
        }
    }


    static func messageToScheduledMessage(_ message: Message, user: User, scheduledAt: CLong, timeToExecute: CLong, status: ScheduledMessageState) -> ScheduledMessage {
        let scheduledMessage = ScheduledMessage()
        scheduledMessage.contact = message.contact
        scheduledMessage.content = message.content
        scheduledMessage.fileSize = message.fileSize
        scheduledMessage.fromId = message.fromId
        scheduledMessage.fromPhone = message.fromPhone
        scheduledMessage.location = message.location
        scheduledMessage.mediaDuration = message.mediaDuration
        scheduledMessage.messageId = message.messageId
        scheduledMessage.thumb = message.thumb
        scheduledMessage.typeEnum = message.typeEnum
        scheduledMessage.toId = message.toId
        scheduledMessage.metatdata = message.metatdata
        scheduledMessage.isBroadcast = message.isBroadcast
        scheduledMessage.scheduledAt = scheduledAt
        scheduledMessage.timeToExecute = timeToExecute
        scheduledMessage.status = status
        scheduledMessage.localPath = message.localPath
        scheduledMessage.chatId = message.chatId
        scheduledMessage.downloadUploadState = .SUCCESS//make it shown even if it's not uploaded yet.
        scheduledMessage.broadcastUids = message.broadcastUids
        scheduledMessage.encryptionType = message.encryptionType
        return scheduledMessage
    }

    static func scheduledMessageToMessage(_ scheduledMessage: ScheduledMessage) -> Message {
        let message = Message()
        message.contact = scheduledMessage.contact
        message.content = scheduledMessage.content
        message.fileSize = scheduledMessage.fileSize
        message.fromId = scheduledMessage.fromId
        message.fromPhone = scheduledMessage.fromPhone
        message.location = scheduledMessage.location
        message.mediaDuration = scheduledMessage.mediaDuration
        message.messageId = scheduledMessage.messageId
        message.thumb = scheduledMessage.thumb
        message.typeEnum = scheduledMessage.typeEnum
        message.toId = scheduledMessage.toId
        message.metatdata = scheduledMessage.metatdata
        message.isBroadcast = scheduledMessage.isBroadcast
        message.timestamp = scheduledMessage.timeToExecute
        message.localPath = scheduledMessage.localPath
        message.downloadUploadState = scheduledMessage.downloadUploadState
        message.chatId = scheduledMessage.chatId
        return message
    }
    
    static func messageToScheduledMessage(message:Message,scheduledMessage:ScheduledMessage) -> ScheduledMessage {
        scheduledMessage.contact = message.contact
        scheduledMessage.content = message.content
        scheduledMessage.location = message.location
        scheduledMessage.thumb = message.thumb
        scheduledMessage.broadcastUids = message.broadcastUids
        scheduledMessage.encryptionType = message.encryptionType
        return scheduledMessage
    }
}

extension ScheduledMessage {
    func toMessage() -> Message {
        return ScheduledMessage.scheduledMessageToMessage(self)
    }
    func completeAfterDownload() -> Bool {
        return downloadUploadState != .CANCELLED && typeEnum != .SENT_DELETED_MESSAGE && typeEnum != .RECEIVED_DELETED_MESSAGE;
    }

    func toMap() -> [String: Any] {

        var result: [String: Any] = [:]

        result[DBConstants.FROM_ID] = fromId
        result[DBConstants.TYPE] = typeEnum.rawValue
        result[DBConstants.CONTENT] = content
        result[DBConstants.MESSAGE_ID] = messageId

        if(isGroup) {
            result[DBConstants.FROM_PHONE] = FireManager.number ?? ""
            result["isGroup"] = true
        } else {
            if (isBroadcast) {
                result["isBroadcast"] = true

            } else {
                result[DBConstants.TOID] = toId
            }
        }


        if mediaDuration != "" {
            result[DBConstants.MEDIADURATION] = mediaDuration
        }

        if thumb != "" {
            result[DBConstants.THUMB] = thumb
        }

        if metatdata != "" {
            result[DBConstants.METADATA] = metatdata
        }

        if(fileSize != "") {
            result[DBConstants.FILESIZE] = fileSize
        }

        if contact != nil {
            result[DBConstants.CONTACT] = contact?.toMap()
        }

        if location != nil {
            let isEncrypted = encryptionType != EncryptionType.NONE
            result[DBConstants.LOCATION] = location?.toMap(isEncrypted: isEncrypted)
        }

        result["scheduledAt"] = ServerValue.timestamp()
        result["timeToExecute"] = timeToExecute
        result["state"] = ScheduledMessageState.scheduled.rawValue


        return result


    }
}




enum ScheduledMessageState: Int {
    case scheduled = 1
    case failed = 2
    case executed = 3
    case uploading = 4
    case unknown = 5

    func getText() -> String {

        switch self {
        case .scheduled:
            return "Scheduled"

        case .failed:
            return "Failed"

        case.executed:
            return "Executed"

        case.uploading:
            return "Uploading"

        default:
            return "Unknown"
        }
    }

}

