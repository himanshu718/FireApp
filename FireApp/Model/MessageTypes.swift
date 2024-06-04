//
//  MessageTypes.swift
//  FireApp
//
//  Created by Devlomi on 7/15/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

enum MessageType: Int {
    case DEFAULT = 0
    case SENT_TEXT = 1
    case SENT_IMAGE = 2
    case RECEIVED_TEXT = 3
    case RECEIVED_IMAGE = 4
    case SENT_VIDEO = 5
    case RECEIVED_VIDEO = 6
    case SENT_AUDIO = 9
    case RECEIVED_AUDIO = 10
    case SENT_VOICE_MESSAGE = 11
    case RECEIVED_VOICE_MESSAGE = 12
    case SENT_FILE = 13
    case RECEIVED_FILE = 14
    case DAY_ROW = 15
    case SENT_CONTACT = 16
    case RECEIVED_CONTACT = 17
    case SENT_LOCATION = 18
    case RECEIVED_LOCATION = 19

    case SENT_DELETED_MESSAGE = 30
    case RECEIVED_DELETED_MESSAGE = 31

    case REPLY_STATUS = 32

    case SENT_STICKER = 33
    case RECEIVED_STICKER = 34

    case STATUS_TYPE = 8888

    case GROUP_EVENT = 9999
    case DATE_HEADER = 999

}
extension MessageType {
    func isSentType() -> Bool {
        let type = self
        return type == .SENT_TEXT || type == .SENT_IMAGE || type == .SENT_VIDEO || type == .SENT_AUDIO
            || type == .SENT_FILE || type == .SENT_VOICE_MESSAGE
            || type == .SENT_CONTACT || type == .SENT_LOCATION
            || type == .SENT_STICKER
    }

    func isText() -> Bool {
        return self == .SENT_TEXT || self == .RECEIVED_TEXT
    }

    func isContact() -> Bool {
        return self == .SENT_CONTACT || self == .RECEIVED_CONTACT
    }

    func isLocation() -> Bool {
        return self == .SENT_LOCATION || self == .RECEIVED_LOCATION
    }
    func isImage() -> Bool {
        return self == .SENT_IMAGE || self == .RECEIVED_IMAGE
    }

    func isVideo() -> Bool {
        return self == .SENT_VIDEO || self == .RECEIVED_VIDEO
    }

    func isVoice() -> Bool {
        return self == .SENT_VOICE_MESSAGE || self == .RECEIVED_VOICE_MESSAGE
    }

    func isDeletedMessage() -> Bool {
        return self == .SENT_DELETED_MESSAGE || self == .RECEIVED_DELETED_MESSAGE
    }


    func isStickerType() -> Bool {
        return self == .SENT_STICKER || self == .RECEIVED_STICKER
    }

    public func isMediaType() -> Bool {
        return
            self == .SENT_IMAGE ||
            self == .RECEIVED_IMAGE ||
            self == .SENT_VIDEO ||
            self == .RECEIVED_VIDEO ||
            self == .SENT_AUDIO ||
            self == .RECEIVED_AUDIO ||
            self == .SENT_VOICE_MESSAGE ||
            self == .RECEIVED_VOICE_MESSAGE ||
            self == .RECEIVED_FILE ||
            self == .SENT_FILE ||
            self == .SENT_STICKER ||
            self == .RECEIVED_STICKER

    }

    //convert sent type to received when receiving a message from other user
    //because by default it's sent when the other user sent it to user
    public func convertSentToReceived() -> MessageType {
        var convertedType = self
        switch (self) {
        case .SENT_TEXT:
            convertedType = .RECEIVED_TEXT
            break;

        case .SENT_AUDIO:
            convertedType = .RECEIVED_AUDIO
            break;


        case .SENT_FILE:
            convertedType = .RECEIVED_FILE
            break;

        case .SENT_IMAGE:
            convertedType = .RECEIVED_IMAGE
            break;

        case .SENT_VIDEO:
            convertedType = .RECEIVED_VIDEO
            break;

        case .SENT_VOICE_MESSAGE:
            convertedType = .RECEIVED_VOICE_MESSAGE
            break;

        case .SENT_CONTACT:
            convertedType = .RECEIVED_CONTACT
            break;

        case .SENT_LOCATION:
            convertedType = .RECEIVED_LOCATION
            break;

        case .SENT_STICKER:
            convertedType = .RECEIVED_STICKER
            break

        default:
            return convertedType
        }

        return convertedType

    }


    public func convertReceivedToSent() -> MessageType {
        var convertedType = self
        switch (self) {
        case .RECEIVED_TEXT:
            convertedType = .SENT_TEXT
            break;

        case .RECEIVED_AUDIO:
            convertedType = .SENT_AUDIO
            break;


        case .RECEIVED_FILE:
            convertedType = .SENT_FILE
            break;

        case .RECEIVED_IMAGE:
            convertedType = .SENT_IMAGE
            break;

        case .RECEIVED_VIDEO:
            convertedType = .SENT_VIDEO
            break;

        case .RECEIVED_VOICE_MESSAGE:
            convertedType = .SENT_VOICE_MESSAGE
            break;

        case .RECEIVED_CONTACT:
            convertedType = .SENT_CONTACT
            break;

        case .RECEIVED_LOCATION:
            convertedType = .SENT_LOCATION
            break;

        case .RECEIVED_STICKER:
            convertedType = .SENT_STICKER
            break

        default:
            return convertedType

        }

        return convertedType

    }
}
