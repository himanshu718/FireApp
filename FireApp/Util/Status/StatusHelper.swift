//
//  StatusHelper.swift
//  FireApp
//
//  Created by Devlomi on 3/20/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
class StatusHelper {

    static func getStatusTypeImageName(statusType: StatusType) -> String {
        return MessageTypeHelper.getMessageTypeImage(type: mapStatusTypeToMessageType(statusType: statusType))
    }

    static func getStatusContent(status: Status) -> String {
        let type = mapStatusTypeToMessageType(statusType: status.type)
        return MessageTypeHelper.getTypeText(type: type)
    }

    static func mapStatusTypeToMessageType(statusType: StatusType) -> MessageType {

        switch statusType {
        case .image:
            return .SENT_IMAGE
        case .video:
            return .SENT_VIDEO
        default:
            return .SENT_TEXT
        }

    }

    public static func statusToMessage(status: Status, userId: String) -> Message {
        let message = Message()
        message.messageId = FireManager.generateKey()
        message.fromId = userId
        message.typeEnum = mapStatusTypeToMessageType(statusType: status.type)
        message.chatId = userId
        message.toId = userId
        message.timestamp = Date().currentTimeMillisLong()
        message.messageState = MessageState.PENDING
        message.downloadUploadState = .LOADING
        message.status = status
        
        if (status.thumbImg != "") {
            message.thumb = status.thumbImg
        }

        return message
    }
}
