//
//  DBConstants.swift
//  FireApp
//
//  Created by Devlomi on 5/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
struct DBConstants{
    static let TOID = "toId"
    static let MEDIADURATION = "mediaDuration"
    static let THUMB = "thumb"
    static let METADATA = "metadata"
    static let FILESIZE = "fileSize"
    static let CONTACT = "contact"
    static let LOCATION = "location"
    static let IS_GROUP = "isGroupBool"
    static let IS_SEEN = "isSeen"
    static let ARE_ALL_STATUSES_SEEN = "areAllSeen"
    static let BROADCASTED_MESSAGE_ID = "broadcastedMessageId"
    
    static let MESSAGE_ID = "messageId"
    
    static let CHAT_ID = "chatId"
    static let TIMESTAMP = "timestamp"
    static let MESSAGE_STAT = "messageStat"
    static let VOICE_MESSAGE_SEEN = "voiceMessageSeen"
    static let FROM_ID = "fromId"
    static let FROM_PHONE = "fromPhone"
    static let ENCRYPTION_TYPE = "encryptionType"
    static let PARTIAL_TEXT = "partialText"

    static let DOWNLOAD_UPLOAD_STAT = "downloadUploadStat"
    static let CONTENT = "content"
    static let TYPE = "type"
    static let LOCAL_PATH = "localPath"
    
    
    static let CHAT_LAST_MESSAGE_TIMESTAMP = "lastMessageTimestamp"
    static let NOTIFICATION_ID = "notificationId"
    static let UNREAD_COUNT = "unReadCount"
    static let isMuted = "isMuted"
    
    
    static let UID = "uid"
    static let USERNAME = "userName"
    static let USER_USERNAME = "user.userName"
    static let PHONE = "phone"
    static let IS_STORED_IN_CONTACTS = "isStoredInContacts"
    
    
    static let isGroupBool = "isGroupBool"
    static let isBroadcastBool = "isBroadcastBool"

    static let GROUP_DOT_IS_ACTIVE = "group.isActive"
    static let GROUP_ID = "groupId"
    
    
    static let JOB_ID = "jobId"
    static let ID = "id"
    static let isVoiceMessage = "isVoiceMessage"
    
    
    static let lastStatusTimestamp = "lastStatusTimestamp"
    static let statusId = "statusId"
    static let statusUserId = "userId"
    
    
    static let CALL_ID = "callId"
    static let CALL_UUID = "callUUID"
    
    static let BROADCAST_ID = "broadcastId"
    
    static let messageNeedsToUpdateState = "messageNeedsToUpdateState"
    static let voiceMessageNeedsToUpdateState = "voiceMessageNeedsToUpdateState"
}
