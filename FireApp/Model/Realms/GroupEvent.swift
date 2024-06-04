//
//  GroupEvent.swift
//  FireApp
//
//  Created by Devlomi on 10/1/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseDatabase
import SwiftEventBus

//group event will contains what happened in a group

class GroupEvent: Object {
    //context start: is like who is started the event
    @objc dynamic var contextStart = ""
    //event type to identify what event is it like ADMIN_CHANGED,USER_ADDED etc..
    @objc dynamic private var eventType = GroupEventType.Default.rawValue

    var type: GroupEventType {
        get {
            return GroupEventType(rawValue: eventType)!
        }
        set {
            eventType = newValue.rawValue
        }

    }
    //context start: is like who is affected with this  event
    @objc dynamic var contextEnd = ""
    @objc dynamic var timestamp = ""
    @objc dynamic var eventId = ""


    convenience init(contextStart: String, type: GroupEventType, contextEnd: String) {
        self.init()
        self.contextStart = contextStart
        self.type = type
        self.contextEnd = contextEnd
    }

    //this will create the group event and save it as a message inside 'Content'
    //it will be save like: contextStart:eventType:contextEnd
    public func createGroupEvent(group: User, eventId: String?) {
        let message = Message()
        message.isGroup = true
        message.chatId = group.uid
        message.toId = group.uid

        message.messageId = eventId == nil ? UUID().uuidString : eventId!

        var content = ""

        if (contextEnd != "") {
            content = contextStart + ":" + "\(eventType)" + ":" + contextEnd
        } else {
            content = contextStart + ":" + "\(eventType)"
        }

        message.content = content
        message.typeEnum = .GROUP_EVENT
        message.messageState = .NONE
        message.timestamp = Date().currentTimeMillisLong()
        RealmHelper.getInstance(appRealm).saveDateMessageIfNeeded(message: message)
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: message, update: false)
        RealmHelper.getInstance(appRealm).saveChatIfNotExists(message: message, user: group)
    }

    //this will extract the string from 'Content' and set as readable-human text
    public static func extractString(messageContent: String, users: List<User>) -> String {
        do {
            let content = messageContent.split(separator: ":")

            let contextStart: String = String(content[0])
            let eventTypeInt: Int = Int(String(content[safe:1] ?? "0")) ?? 0
            let eventType:GroupEventType = GroupEventType(rawValue: eventTypeInt) ?? .UNKNOWN
            var contextEnd = String(content[safe: 2] ?? "")

            var finalText = ""

            let currentUserPhoneNumber = FireManager.number ?? ""

            switch eventType {
            case GroupEventType.ADMIN_ADDED:

                if contextEnd == currentUserPhoneNumber {
                    finalText = "\(Strings.you) \(Strings.are_now_an_admin)"
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextEnd, users: users) + " " + Strings.is_now_an_admin
                }

                break;
            case GroupEventType.ADMIN_REMOVED:
                if contextEnd == currentUserPhoneNumber {
                    finalText = "\(Strings.you) \(Strings.no_longer_an_admin)"
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextEnd, users: users) + " " + Strings.no_longer_an_admin
                }
                break;
            case GroupEventType.USER_ADDED:
                if contextStart == currentUserPhoneNumber {
                    finalText = Strings.you + " " + Strings.added + " ";
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextStart, users: users) + " " + "\(Strings.added)" + " ";
                }

                if contextEnd == currentUserPhoneNumber {
                    finalText += Strings.you
                } else {
                    finalText += getUserNameFromGroupEvent(number: contextEnd, users: users)
                }
                break;
            case GroupEventType.USER_LEFT_GROUP:
                if contextStart == currentUserPhoneNumber {
                    finalText = "\(Strings.you_left)" + " ";
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextStart, users: users) + " " + "\(Strings.left_group)" + " ";
                }
                break;
            case GroupEventType.USER_REMOVED_BY_ADMIN:
                if contextStart == currentUserPhoneNumber {
                    finalText = "\(Strings.you_removed)" + " ";
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextStart, users: users) + " " + "\(Strings.removed)" + " ";
                }

                contextEnd = String(content[2])

                if contextEnd == currentUserPhoneNumber {
                    finalText += Strings.you
                } else {
                    finalText += getUserNameFromGroupEvent(number: contextEnd, users: users);
                }
                break;

            case GroupEventType.GROUP_CREATION:
                if contextStart == currentUserPhoneNumber {
                    finalText = "\(Strings.you_created_this_group)" + " "
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextStart, users: users) + " " + Strings.created_this_group
                }
                break;


            case GroupEventType.GROUP_SETTINGS_CHANGED:
                if contextStart == currentUserPhoneNumber {
                    finalText = Strings.you_changed_group_preferences + " ";
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextStart, users: users) + " " + Strings.changed_group_preferences;
                }
                break;

            case GroupEventType.JOINED_VIA_LINK:
                if contextStart == currentUserPhoneNumber {
                    finalText = Strings.you + " " + Strings.joined_via_link
                } else {
                    finalText = getUserNameFromGroupEvent(number: contextStart, users: users) + " " + Strings.joined_via_link
                }

                break;
            case .Default,.UNKNOWN:
                return ""
        
            }
            return finalText;
        }
    }

    //this will get the user name from the number
    private static func getUserNameFromGroupEvent(number: String, users: List<User>) -> String {
        let user = users.filter { $0.phone == number }.first

        if let user = user {
            return getUserNameOrPhone(user: user)
            
        }
        
        if let user = RealmHelper.getInstance(appRealm).getUserByPhone(phone:number){
            return getUserNameOrPhone(user: user)
        }
              

        return number
    }
    
    //return Phone number if user name is not exist
    //since a user maybe removed from a group
    private static func getUserNameOrPhone(user: User) -> String {
        if (user.userName == "") {
            return user.phone
        }

        return user.userName
    }
    
    private func getQuotedUserName(quotedMessage: QuotedMessage, user: User) -> String {
        if quotedMessage.fromId == FireManager.getUid() {
            return Strings.you
        }
        if let userName = user.getUserNameByIdForGroups(userId: quotedMessage.fromId) {
            return userName
        }

        return quotedMessage.fromPhone

    }
}

enum GroupEventType: Int {

    case Default = 0
    case ADMIN_ADDED = 1
    case USER_ADDED = 2
    case USER_REMOVED_BY_ADMIN = 3
    case USER_LEFT_GROUP = 4
    case GROUP_SETTINGS_CHANGED = 5
    case GROUP_CREATION = 6
    case ADMIN_REMOVED = 7
    case JOINED_VIA_LINK = 8
    case UNKNOWN = 99
}


extension DataSnapshot {
    func toGroupEvent() -> GroupEvent {
        let eventId = self.key
        let contextStart = self.childSnapshot(forPath: "contextStart").value as? String ?? ""
        let contextEnd = self.childSnapshot(forPath: "contextEnd").value as? String ?? ""
        let eventType = self.childSnapshot(forPath: "eventType").value as? Int ?? 0
        let timestamp = self.childSnapshot(forPath: "timestamp").value as? String ?? ""

        let groupEvent = GroupEvent(contextStart: contextStart, type: GroupEventType(rawValue: eventType)!, contextEnd: contextEnd)
        groupEvent.eventId = eventId
        groupEvent.timestamp = timestamp
        
        return groupEvent

    }
}
