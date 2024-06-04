//
//  FireConstants.swift
//  FireApp
//
//  Created by Devlomi on 9/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

class FireConstants {
    static let database = Database.database()
    static let storage = Storage.storage()
    static let mainRef = database.reference()
    //users ref that contain user's data (name,phone,photo etc..)
    static let usersRef = mainRef.child("users")

    static let pkPwd = mainRef.child("pkPwd");
    
    static let deviceIdRef = mainRef.child("deviceId");

    //groups ref that contains user ids and group info
    static let groupsRef = mainRef.child("groups")
    static let groupsEventsRef = mainRef.child("groupEvents")

    //this will contain all groups ids that the user participated to
    static let groupsByUser = mainRef.child("groupsByUser")

    //this will get whom added the user to a group
    static let groupMemberAddedBy = mainRef.child("groupMemberAddedBy")
    //this holds groups links
    static let groupsLinks = mainRef.child("groupsLinks")
    static let groupLinkById = mainRef.child("groupLinkById")
    //this is used when an admin removes a group member so the removed user will not be able
    //to re join this group via link again.
    static let deletedGroupsUsers = mainRef.child("groupsDeletedUsers")

    //this holds broadcasts data like info and users
    static let broadcastsRef = mainRef.child("broadcasts")
    //this holds broadcasts messages
    static let broadcastsMessagesRef = mainRef.child("broadcastsMessages")
    //used when user uninstalled and reinstalled to re-fetch the broadcast
    static let broadcastsByUser = mainRef.child("broadcastsByUser")

    //this will save the UID's of the users whom saw the status
    static let statusSeenUidsRef = mainRef.child("statusSeenUids")

    //this will get the status count
    static let statusCountRef = mainRef.child("statusCount")

    //this will delete a message for all users
    static let deleteMessageRequests = mainRef.child("deleteMessageRequests")

    static let deleteMessageRequestsForGroup = mainRef.child("deleteMessageRequestsForGroup")

    static let deleteMessageRequestsForBroadcast = mainRef.child("deleteMessageRequestsForBroadcast")


    //this is the MAJOR ref ,all messages goes in this ref
    static let messages = mainRef.child("messages")

    static let userMessages = mainRef.child("userMessages")
    static let vendorOrders = mainRef.child("vendorOrders")
    static let backupRef = mainRef.child("backup")

    static let groupsMessages = mainRef.child("groupsMessages")
    //this ref is for the messages sates (received,read)
    static let messageStat = mainRef.child("messages-stat")
    //this ref is for the voice messages sates (is listened or not yet)
    static let voiceMessageStat = mainRef.child("voice-messages-stat")
    static let updateRef = mainRef.child("updateMode").child("ios")

    //all statuses goes here
    static let statusRef = mainRef.child("status")
    static let textStatusRef = mainRef.child("textStatus")

    //this will save if calls is missed or not
    static let callsRef = mainRef.child("calls")

    static let newCallsRef = mainRef.child("newCalls")
    static let userCalls = mainRef.child("userCalls")
    static let groupCallsRef = mainRef.child("groupCalls");

    static let missedCalls = mainRef.child("missedCalls");

    //this ref is for the user state is he online or not ,if he is not online this will contain the last seen timestamp
    static let presenceRef = mainRef.child("presence")

    //this will have the user typing or recording or do nothing value when he chatting with another user
    static let typingStat = mainRef.child("typingStat")

    static let groupTypingStat = mainRef.child("groupTypingStat")


    //this is used when the user blocks another user it will save the blocked uid
    static let blockedUsersRef = mainRef.child("blockedUsers")

    //this will get the user id by his phone number to use it when searching for a user
    static let uidByPhone = mainRef.child("uidByPhone")


    static let storageRef = storage.reference()
    //firebase storage folders ,used when uploading or downloading
    static let imageRef = storageRef.child("image")
    static let imageProfileRef = storageRef.child("image_profile")
    static let videoRef = storageRef.child("video")
    static let voiceRef = storageRef.child("voice")
    static let fileRef = storageRef.child("file")
    static let audioRef = storageRef.child("audio")
    static let statusStorageRef = storageRef.child("status")
    static let backupStorageRef = storageRef.child("backup")

    static let deletedUsers = mainRef.child("deletedUsers")

    //MAX SIZE FOR FCM message IS 4096 ,however we want some more space for other items regardless "Content"
    static let MAX_SIZE_STRING = 3800

    static func getMessageRef(isGroup: Bool, isBroadcast: Bool, groupOrBroadcastId: String) -> DatabaseReference {
        if (isGroup) {
            return groupsMessages.child(groupOrBroadcastId)
        }
        if (isBroadcast) {
            return broadcastsMessagesRef.child(groupOrBroadcastId)
        }

        return messages
    }

    public static func getDeleteMessageRequestsRef(messageId: String, isGroup: Bool, isBroadcast: Bool, groupOrBroadcastId: String) -> DatabaseReference {

        if (isGroup) {
            return deleteMessageRequestsForGroup.child(groupOrBroadcastId).child(messageId)
        } else if (isBroadcast) {
            return deleteMessageRequestsForBroadcast.child(groupOrBroadcastId).child(messageId)
        }
        return deleteMessageRequests.child(messageId)
    }


    

    //get correct ref for the given type
    public static func getRef(type: MessageType, fileName: String, isStatus: Bool = false) -> StorageReference {
        let mName = UUID().uuidString + "." + fileName.fileExtension()

        if isStatus {
            return FireConstants.statusStorageRef.child(mName);
        }
        switch (type) {

        case MessageType.SENT_IMAGE:
            return FireConstants.imageRef.child(mName);

        case MessageType.SENT_VIDEO:
            return FireConstants.videoRef.child(mName);

        case MessageType.SENT_VOICE_MESSAGE:
            return FireConstants.voiceRef.child(mName);

        case MessageType.SENT_AUDIO:
            return FireConstants.audioRef.child(mName);

        default:
            return FireConstants.fileRef.child(mName);

        }
    }
}
