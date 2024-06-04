//
// Created by Devlomi on 2019-07-16.
// Copyright (c) 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseDatabase
import RxSwift
import SwiftEventBus
import Realm


class RealmHelper {
    typealias Transaction = () -> Void

    typealias MessageCallback = (Message?) -> Void

    private static var instance: RealmHelper?

    private var uiRealm: Realm!

    private init(realm: Realm) {
        uiRealm = realm
    }
    static func getInstance(_ realm: Realm? = nil) -> RealmHelper {
        if instance == nil {
            instance = RealmHelper(realm: realm!)
        }
        return instance!
    }
//    static func getInstance(_ realm: Realm? = nil) -> RealmHelper {
//
//        if instance == nil {
//            if let unwrappedRealm = realm {
//                instance = RealmHelper(realm: unwrappedRealm)
//            } else {
//                // Handle the case where realm is nil, or provide a default value if needed
//                print("Realm is nil. Using default Realm or handle it accordingly.")
//                instance = RealmHelper(realm: realm!)  // Replace with your default behavior
//            }
//        }
//        return instance!
//    }

    func saveObjectToRealm(object: Object, update: Bool = true) {
        openTransaction {
            if update {
                uiRealm.add(object, update: .modified)
            } else {
                uiRealm.add(object)
            }
        }
    }

    func saveObjectToRealmSafely(object: Object, update: Bool = true) {
        try! uiRealm.safeWrite {
              if update {
                  uiRealm.add(object, update: .modified)
              } else {

                  uiRealm.add(object)
              }
          }
      }


    private func openTransaction(transaction: Transaction) {
        try! uiRealm.write {
            transaction()
        }
    }
    
    func saveCurrentUidAndDeleteOldOne(new:CurrentUid) {
        openTransaction {
            if let currentUid = getCurrentUid(){
                uiRealm.delete(currentUid)
            }
            uiRealm.add(new)
        }
        
    }
    
    func shouldDeleteAfterLogin(newUid:String) -> Bool{
        if let currentUid = getCurrentUid(){
            return currentUid.uid != newUid
        }
        return false
    }
    
    
    func getCurrentUid() -> CurrentUid? {
        return uiRealm.objects(CurrentUid.self).first
    }
    
    func deleteRealm()  {
        try? uiRealm.write{
            uiRealm.deleteAll()
        }
    }


    func deleteMessages(messages: [Message]) {
        for message in messages {
            if message.localPath != "" {
                try? URL(fileURLWithPath: message.localPath).deleteFile()
            }
        }
        //since all callers of this method will be executed from the same chat (the chatId will be the same)

        if messages.isEmpty {
            return
        }

        let sortedMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })

        //copy it to an array
        let sortedMessagesArray = Array(sortedMessages)
        //filter DateEvents in these messages to delete it if needed
        let timestamps = getDistinctMessagesTimestamps(messages: sortedMessagesArray)


        let chatId = messages.first!.chatId

        if let chat = getChat(id: chatId), let lastMessage = sortedMessages.last {

            updateLastMessageForChat(messageToDelete: lastMessage, chat: chat)
        }

        openTransaction {
            uiRealm.delete(messages)

            //delete DateHeader if needed
            for timestamp in timestamps {
                let date = timestamp.toDate()
                let messagesInChatForDay = getMessagesInChatForDay(chatId: chatId, date: date)
                if messagesInChatForDay.count == 1, let firstMessage = messagesInChatForDay.first, !firstMessage.isInvalidated {
                    uiRealm.delete(firstMessage)
                }
            }
        }

    }

    private func getMessagesInChatForDay(chatId: String, date: Date) -> Results<Message> {
        let todayStart = Calendar.current.startOfDay(for: date)
        let todayEnd: Date = {
            let components = DateComponents(day: 1, second: -1)
            return Calendar.current.date(byAdding: components, to: todayStart)!
        }()

        return getMessagesInChat(chatId: chatId).filter("timestamp BETWEEN %@", [todayStart.currentTimeMillisLong(), todayEnd.currentTimeMillisLong()])
    }

    private func getDistinctMessagesTimestamps(messages: [Message]) -> [CLong] {
        var timestamps = [Int: CLong]()
        for i in 0...messages.count - 1 {
            let timestamp = messages[i].timestamp

            if (i == 0) {
                timestamps[i] = timestamp
            } else {
                let oldTimestamp = messages[i - 1].timestamp
                if (!TimeHelper.isSameDay(timestamp: timestamp.toDate(), oldTimestamp: oldTimestamp.toDate())) {
                    timestamps[i] = timestamp
                }
            }
        }
        return Array(timestamps.values)
    }

    private func updateLastMessageForChat(messageToDelete: Message, chat: Chat) {

        //get last message in this chat
        if let lastMessage = chat.lastMessage {
            //if this is last message in chat then we want to update
            // 'Chat' with new LastMessage (the message before last message)
            if lastMessage.messageId == messageToDelete.messageId {
                let messagesInChat = getMessagesInChat(chatId: chat.chatId)
//                   RealmResults<Message> messagesInChat = realm.where(Message.class).equalTo(DBConstants.CHAT_ID, chatId).findAll();
//                   int messagesCount = messagesInChat.size();
                let messagesCount = messagesInChat.count
                //check if there is more than one message in this chat
                if messagesCount > 1 {
                    //get the message before the last message (the new message to set it as the last message)
                    let messageToSetAsLastMessage = messagesInChat[messagesCount - 2]
                    //update the chat with the new last message
                    saveLastMessageForChat(chatId: chat.chatId, message: messageToSetAsLastMessage)
                } else {
                    //if there are no messages in chat then just update
                    // the timestamp with the last message timestamp to keep the chat order

                    if let lastMessageInChat = messagesInChat.last {
                        saveChatLastMessageTimestamp(chat: chat, timestamp: lastMessageInChat.timestamp)
                    }

                }
            }

        }
    }

    private func saveChatLastMessageTimestamp(chat: Chat, timestamp: CLong) {
        openTransaction {
            chat.lastMessageTimestamp = String(timestamp)
        }
    }
    
    func getMessage(messageId: String) -> Message? {
        return uiRealm.objects(Message.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'").first
    }

    func getMessage(messageId: String, chatId: String) -> Message? {
        return uiRealm.objects(Message.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)' AND \(DBConstants.CHAT_ID) == '\(chatId)'").first
    }
    
    
    func getTempMessage(messageId: String) -> TempMessage? {
        return uiRealm.objects(TempMessage.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'").first
    }
    
    func deleteTempMessage(messageId:String)  {
        let tempMessages = uiRealm.objects(TempMessage.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'")
        openTransaction {
            uiRealm.delete(tempMessages)
        }
    }
    
    
    func saveUnreadMessage(messageId: String, chatId: String) {
        guard let message = getMessage(messageId: messageId, chatId: chatId) else {
            return
        }
        
        guard let chat = getChat(id: chatId) else {
            return
        }
        
        let unReadCount = chat.unReadCount
        let unreadMessages = chat.unreadMessages
    
        try! uiRealm.write {
            unreadMessages.append(message)
            chat.unReadCount += 1
            
            if chat.firstUnreadMessageId.isEmpty{
                chat.firstUnreadMessageId = message.messageId
            }
            
        }
        
    }

    
    func deleteUnReadMessages(chatId : String){
        if let chat = getChat(id: chatId) {
            let unreadMessages = chat.unreadMessages
            try! uiRealm.write {
                chat.unReadCount = 0
                
                for unreadMessage in unreadMessages {
                    unreadMessage.isSeen = true
                }
                unreadMessages.removeAll()
            }
        }
    }

    func getMediaInChat(chatId: String) -> Results<Message> {
        let chatIdQuery = "chatId == '\(chatId)'"
        var stringQuery = String()
        stringQuery.append("\(chatIdQuery) and \(DBConstants.TYPE) == \(MessageType.SENT_IMAGE.rawValue) or ")
        stringQuery.append("\(chatIdQuery) and \(DBConstants.TYPE) == \(MessageType.RECEIVED_IMAGE.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) == \(DownloadUploadState.SUCCESS.rawValue) or ")
        stringQuery.append("\(chatIdQuery) and \(DBConstants.TYPE) == \(MessageType.SENT_VIDEO.rawValue) or ")
        stringQuery.append("\(chatIdQuery) and \(DBConstants.TYPE) == \(MessageType.RECEIVED_VIDEO.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) ==\(DownloadUploadState.SUCCESS.rawValue)")


        return uiRealm.objects(Message.self)
            .filter(stringQuery)
            .sorted(byKeyPath: DBConstants.TIMESTAMP)



    }
    
    func getAllMedia() -> Results<Message> {
        var stringQuery = String()
        stringQuery.append(" \(DBConstants.TYPE) == \(MessageType.SENT_IMAGE.rawValue) or ")
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.RECEIVED_IMAGE.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) == \(DownloadUploadState.SUCCESS.rawValue) or ")
        
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.SENT_VIDEO.rawValue) or ")
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.RECEIVED_VIDEO.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) ==\(DownloadUploadState.SUCCESS.rawValue) or ")
        
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.SENT_VOICE_MESSAGE.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) ==\(DownloadUploadState.SUCCESS.rawValue) or ")
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.RECEIVED_VOICE_MESSAGE.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) ==\(DownloadUploadState.SUCCESS.rawValue) or ")
        
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.SENT_STICKER.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) ==\(DownloadUploadState.SUCCESS.rawValue) or ")
        stringQuery.append("\(DBConstants.TYPE) == \(MessageType.RECEIVED_STICKER.rawValue) and \(DBConstants.DOWNLOAD_UPLOAD_STAT) ==\(DownloadUploadState.SUCCESS.rawValue) ")
        

        return uiRealm.objects(Message.self)
            .filter(stringQuery)
            .sorted(byKeyPath: DBConstants.TYPE)



    }

    func getMessages(messageId: String) -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'")

    }


    func updateMessageStateLocally(messageId: String, messageState: MessageState) {
        let messages = getMessages(messageId: messageId)

        openTransaction {

            for message in messages {
                message.messageState = messageState
            }
        }

    }

    func updateMessageStateLocally(messageId: String, chatId: String, messageState: MessageState) {
        guard let message = getMessage(messageId: messageId, chatId: chatId) else {
            return
        }

        openTransaction {
            message.messageState = messageState
        }
    }
    
    



    func updateVoiceMessageStateLocally(messageId: String, chatId: String) {
        guard let message = getMessage(messageId: messageId, chatId: chatId) else {
            return
        }

        if message.voiceMessageSeen {
            return
        }

        openTransaction {
            message.voiceMessageSeen = true
        }
    }

    func updateVoiceMessageStateLocally(messageId: String) {
        guard let message = getMessage(messageId: messageId) else {
            return
        }

        if message.voiceMessageSeen {
            return
        }

        openTransaction {
            message.voiceMessageSeen = true
        }
    }

    func changeDownloadOrUploadStat(messageId: String, state: DownloadUploadState) {
        guard let message = getMessage(messageId: messageId) else {
            return
        }

        openTransaction {
            message.downloadUploadState = state
        }
    }

    //update upload state when it's finished whether it's success ,failed,loading or cancelled
    public func updateDownloadUploadStat(messageId: String, downloadUploadStat: DownloadUploadState) {
        //we are getting all messages because it's may be a broadcast ,if so we want to update the state of all of them
        let messages = getMessages(messageId: messageId)
        openTransaction {
            for message in messages {
                //if upload state is success ,update the message state to sent
                if downloadUploadStat == .SUCCESS {
                    message.messageState = .SENT
                }
                message.downloadUploadState = downloadUploadStat
            }
        }

    }

    //update upload state when it's finished whether it's success ,failed,loading or cancelled
    public func updateDownloadUploadStat(messageId: String, downloadUploadStat: DownloadUploadState, filePath: String) {
        //we are getting all messages because it's may be a broadcast ,if so we want to update the state of all of them
        let messages = getMessages(messageId: messageId)
        openTransaction {
            for message in messages {
                //if upload state is success ,update the message state to sent
                if downloadUploadStat == .SUCCESS {
                    message.messageState = .SENT
                }
                message.downloadUploadState = downloadUploadStat
                message.localPath = filePath
            }
        }
    }
    
    
    func changeMessageContent(messageId: String, content: String) {
        guard let message = getMessage(messageId: messageId) else {
            return
        }

        openTransaction {
            message.content = content
        }
    }
    
    func getUsers() -> Results<User> {
        let currentUserFilterPredicate = NSPredicate(format: "NOT (\(DBConstants.UID) IN %@)", [FireManager.getUid()])

        return uiRealm.objects(User.self).filter(currentUserFilterPredicate).filter("\(DBConstants.isGroupBool) == false AND \(DBConstants.isBroadcastBool) == false AND \(DBConstants.IS_STORED_IN_CONTACTS) == true AND isDeleted == false").sorted(byKeyPath: DBConstants.USERNAME)
    }

    func getForwardList() -> Results<User> {
        let currentUserFilterPredicate = NSPredicate(format: "NOT (\(DBConstants.UID) IN %@)", [FireManager.getUid()])

        return uiRealm.objects(User.self).filter(currentUserFilterPredicate).filter("\(DBConstants.isGroupBool) == true AND \(DBConstants.GROUP_DOT_IS_ACTIVE) == true OR \(DBConstants.isGroupBool) == false AND isDeleted == false").sorted(byKeyPath: DBConstants.USERNAME)
    }

    func searchForForwardUser(query: String) -> Results<User> {
        let currentUserFilterPredicate = NSPredicate(format: "NOT (\(DBConstants.UID) IN %@)", [FireManager.getUid()])

        return uiRealm.objects(User.self).filter(currentUserFilterPredicate).filter("\(DBConstants.isGroupBool) == true AND \(DBConstants.GROUP_DOT_IS_ACTIVE) == true OR \(DBConstants.isGroupBool) == false AND \(DBConstants.USERNAME) contains[cd] '\(query)' OR \(DBConstants.PHONE) contains '\(query)'").sorted(byKeyPath: DBConstants.USERNAME)
    }

    func getChats() -> Results<Chat> {
        return uiRealm.objects(Chat.self).sorted(byKeyPath: DBConstants.CHAT_LAST_MESSAGE_TIMESTAMP, ascending: false)
    }
    
    
    func getChats1() -> (results: Results<Chat>, count: Int) {
        let sortedChats = uiRealm.objects(Chat.self).sorted(byKeyPath: DBConstants.CHAT_LAST_MESSAGE_TIMESTAMP, ascending: false)
        let chatCount = sortedChats.count
        return (sortedChats, chatCount)
    }

    public func saveChatIfNotExists(message: Message, user: User) {
        let chatId = message.chatId
        if (!isChatStored(id: chatId)) {
            let chat = Chat()
            chat.chatId = chatId
            chat.user = user
            chat.lastMessageTimestamp = Date().currentTimeMillisStr()
            saveObjectToRealm(object: chat)
        }
        saveLastMessageForChat(chatId: chatId, message: message)
    }
    
    public func isChatStored(id: String) -> Bool {
        return !uiRealm.objects(Chat.self).filter("\(DBConstants.CHAT_ID) == '\(id)'").isEmpty
    }

    public func saveLastMessageForChat(chatId: String, message: Message) {
        guard let chat = getChat(id: chatId) else {
            return
        }
        openTransaction {
            chat.lastMessage = message
            chat.lastMessageTimestamp = String(message.timestamp)
            uiRealm.add(chat)
        }
    }

    func getUser(uid: String) -> User? {
        return uiRealm.objects(User.self).filter("\(DBConstants.UID) == '\(uid)' ").first
    }

    func getUserByPhone(phone: String) -> User? {
        return uiRealm.objects(User.self).filter("\(DBConstants.PHONE) == '\(phone)' ").first
    }

    func getBroadcast(broadcastId: String) -> Broadcast? {
        return uiRealm.objects(Broadcast.self).filter("\(DBConstants.BROADCAST_ID) == '\(broadcastId)' ").first
    }

    func getGroup(groupId: String) -> Results<Group> {
        return uiRealm.objects(Group.self).filter("\(DBConstants.GROUP_ID) == '\(groupId)'")
    }
    public func getChat(id: String) -> Chat? {
        return uiRealm.objects(Chat.self).filter("\(DBConstants.CHAT_ID) == '\(id)' ").first
    }
    
    //update user img if it's different
    public func updateUserImg(uid: String, imgUrl: String, localPath: String, oldLocalPath: String,thumbImg:String?=nil) {
        guard let user = getUser(uid: uid) else {
            return
        }
        openTransaction {
            //save the user url in realm if it's not exists
            if (user.photo == "") {
                user.photo = imgUrl
            }
            else {
                //check if it's different
                if (user.photo != imgUrl) {
                    user.photo = imgUrl
                }

                //set user photo path in device
                user.userLocalPhoto = localPath

            }
            //delete old photo from device
            if oldLocalPath != "" {
                try? URL(fileURLWithPath: oldLocalPath).deleteFile()
            }
            
            if let thumb = thumbImg{
                user.thumbImg = thumb
            }

        }
    }

    public func updateThumbImg(uid: String, thumbImg: String) {
        guard let user = getUser(uid: uid) else {
            return
        }

        openTransaction {
            user.thumbImg = thumbImg
        }
    }

    //get all messages in chat sorted by time
    public func getMessagesInChat(chatId: String) -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.CHAT_ID) == '\(chatId)'").sorted(byKeyPath: DBConstants.TIMESTAMP)
    }

    public func setChatMuted(chatId: String, isMuted: Bool) {
        guard let chat = getChat(id: chatId) else {
            return
        }
        openTransaction {
            chat.isMuted = isMuted
        }
    }

    public func setUserBlocked(uid: String, setBlocked: Bool) {
        guard let user = getUser(uid: uid) else {
            return
        }
        openTransaction {
            user.isBlocked = setBlocked
        }
    }
    public func clearChat(chatId: String) -> Observable<Void> {
        let messagesManaged = getMessagesInChat(chatId: chatId)
        let messages = Array(messagesManaged)
        let paths = messages.filter { $0.localPath != "" }.map { $0.localPath }

        return Observable.from(paths).map { path in
            do {
                try URL(fileURLWithPath: path).deleteFile()
            } catch let error {
            }
        }.do(onCompleted: {
            DispatchQueue.main.async {
                self.openTransaction {
                    if let chat = self.getChat(id: chatId){
                        chat.lastMessage = nil
                        chat.unReadCount = 0
                    }
                    self.uiRealm.delete(messages)
                }
            }
        })
    }
    
    func isExists(messageId: String) -> Bool {
        let realm = try! Realm()
        let messages = realm.objects(Message.self).filter("\(DBConstants.MESSAGE_ID) == %@", messageId)
        return !messages.isEmpty
    }
    
    
    
    public func deleteChat(chatId: String) -> Observable<Void> {
        let messagesManaged = getMessagesInChat(chatId: chatId)
        let messages = Array(messagesManaged)

        let paths = messages.filter { $0.localPath != "" }.map { $0.localPath }
        return Observable.from(paths).map { path in
            do {
                try URL(fileURLWithPath: path).deleteFile()
            } catch let error {
            }
        }.do(onCompleted: {
            DispatchQueue.main.async {
                self.openTransaction {
                    self.uiRealm.delete(messages)
                    if let chat = self.getChat(id: chatId) {
                        self.uiRealm.delete(chat)
                    }
                }
            }
        })
    }

    public func setOnlyAdminsCanPostInGroup(groupId: String, bool: Bool) {
        guard let chat = getChat(id: groupId), let group = chat.user?.group else {
            return
        }
        openTransaction {
            group.onlyAdminsCanPost = bool
        }
    }

    public func deleteGroupMember(groupId: String, userToRemove uid: String) {
        guard let groupUser = getUser(uid: groupId), let userToDelete = getUser(uid: uid), let group = groupUser.group else {
            return
        }

        let users = group.users
        let adminUids = group.adminUids
        
        GroupEvent(contextStart: UserDefaultsManager.getPhoneNumber()!, type: .USER_REMOVED_BY_ADMIN, contextEnd: userToDelete.phone).createGroupEvent(group: groupUser, eventId: nil)
        
        openTransaction {

            if let index = users.index(of: userToDelete) {
                users.remove(at: index)
                
            }

            //remove admin if he is an admin
            if let adminUidIndex = adminUids.index(of: userToDelete.uid) {
                adminUids.remove(at: adminUidIndex)
            }

        }
    }

    public func setGroupAdmin(groupId: String, userToSet uid: String, setAdmin: Bool) {
        guard let groupUser = getUser(uid: groupId), let group = groupUser.group else {
            return
        }

        openTransaction {
            let adminUids = group.adminUids

            if !setAdmin {
                if let index = group.adminUids.index(of: uid) {
                    adminUids.remove(at: index)
                }
            } else {
                adminUids.append(uid)
            }
        }
    }

    public func addUsersToGroup(groupId: String, usersToAdd users: [User]) {
        guard let groupUser = getUser(uid: groupId), let group = groupUser.group else {
            return
        }
        openTransaction {
            group.users.append(objectsIn: users)
        }
    }

    public func changeGroupName(groupId: String, groupName: String) {
        guard let groupUser = getUser(uid: groupId), let group = groupUser.group else {
            return
        }

        if groupUser.userName != groupName {
            openTransaction {
                groupUser.userName = groupName
            }
        }
    }

    public func setGroupLink(groupId: String, groupLink: String) {
        guard let group = getUser(uid: groupId)?.group else {
            return
        }

        openTransaction {
            group.currentGroupLink = groupLink
        }
    }

    public func searchForMessage(chatId: String, query: String) -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.CHAT_ID) == '\(chatId)' AND \(DBConstants.CONTENT) contains[cd] '\(query)' AND (\(DBConstants.TYPE) == \(MessageType.SENT_TEXT.rawValue) OR \(DBConstants.TYPE) == \(MessageType.RECEIVED_TEXT.rawValue))")
    }


    public func searchForChat(query: String) -> Results<Chat> {
        return uiRealm.objects(Chat.self).filter("\(DBConstants.USER_USERNAME) contains[cd] '\(query)'")
    }

    public func searchForUser(query: String) -> Results<User> {
        return getUsers().filter(" \(DBConstants.USERNAME) contains[cd] '\(query)' OR \(DBConstants.PHONE) contains '\(query)'")
    }

    public func searchForUserInGroup(query: String,users:List<User>) -> Results<User> {
        return users.filter(" \(DBConstants.USERNAME) contains[cd] '\(query)' OR \(DBConstants.PHONE) contains '\(query)'")
    }

    public func saveDateMessageIfNeeded(message: Message) {
        //if there is no previous message or if chat is empty save the time header
        guard let chat = getChat(id: message.chatId), let lastMessage = chat.lastMessage else {
            saveDateMessage(chatId: message.chatId, timestamp: message.timestamp)
            return
        }


        // if it's a new day save time header
        if !TimeHelper.isSameDay(timestamp: message.timestamp.toDate(), oldTimestamp: lastMessage.timestamp.toDate()) {
            saveDateMessage(chatId: message.chatId, timestamp: message.timestamp)
        }



    }
    private func saveDateMessage(chatId: String, timestamp: CLong) {
        let message = Message()
        message.messageId = UUID().uuidString
        message.chatId = chatId
        message.fromId = FireManager.getUid()
        message.toId = chatId
        message.timestamp = timestamp

        message.typeEnum = MessageType.DATE_HEADER
        message.messageState = .NONE
        saveObjectToRealm(object: message, update: false)
    }

    public func saveEmptyChat(user: User) {
        let chatId = user.uid

        if chatId != ""{
            if (!isChatStored(id: chatId)) {
                let chat = Chat()
                chat.chatId = chatId
                chat.user = user
                chat.lastMessageTimestamp = Date().currentTimeMillisStr()
                saveObjectToRealm(object: chat)
            }
        }
    }

    public func deleteBroadcast(broadcastId: String) {
        let broadcastUser = getUser(uid: broadcastId)
        let broadcastChat = getChat(id: broadcastId)
        let broadcast = getBroadcast(broadcastId: broadcastId)
        let messagesInChat = getMediaInChat(chatId: broadcastId)

        openTransaction {
            if let broadcastUser = broadcastUser {
                uiRealm.delete(broadcastUser)
            }
            if let broadcastChat = broadcastChat {
                uiRealm.delete(broadcastChat)
            }

            if let broadcast = broadcast {
                uiRealm.delete(broadcast)
            }

            uiRealm.delete(messagesInChat)
        }
    }

    public func addUserToBroadcast(broadcastId: String, user: User) {
        guard let broadcast = getBroadcast(broadcastId: broadcastId) else {
            return
        }
        openTransaction {
            broadcast.users.append(user)
        }

    }

    public func updateBroadcastUsers(broadcastId: String, users: [User]) {
        guard let broadcastUser = getUser(uid: broadcastId), let broadcast = broadcastUser.broadcast else {
            return
        }

        openTransaction {
            broadcast.users.removeAll()
            broadcast.users.append(objectsIn: users)
        }
    }

    public func changeBroadcastName(broadcastId: String, broadcastName: String) {
        guard let broadcastUser = getUser(uid: broadcastId) else {
            return
        }
        openTransaction {
            broadcastUser.userName = broadcastName
        }

    }

    public func getAllStatuses() -> Results<UserStatuses> {
        let sortProperties = [SortDescriptor(keyPath: DBConstants.ARE_ALL_STATUSES_SEEN, ascending: true), SortDescriptor(keyPath: DBConstants.lastStatusTimestamp, ascending: false)]


        let currentUserFilterPredicate = NSPredicate(format: "NOT (\(DBConstants.statusUserId) IN %@)", [FireManager.getUid()])
        let predicate = "\(DBConstants.lastStatusTimestamp) >= \(TimeHelper.getTimeBefore24Hours()) AND statuses.@count > 0"


        return uiRealm.objects(UserStatuses.self).filter(currentUserFilterPredicate).filter(predicate)
            .sorted(by: sortProperties)
    }

    public func getStatuses() -> Results<Status> {
        let currentUserFilterPredicate = NSPredicate(format: "NOT (\(DBConstants.statusUserId) IN %@)", [FireManager.getUid()])
        return uiRealm.objects(Status.self).filter(currentUserFilterPredicate)
    }

    public func searchForStatus(text: String) -> Results<UserStatuses> {
        return getAllStatuses().filter("\(DBConstants.USER_USERNAME) contains[cd] '\(text)'")
    }

    public func getAllStatuses(_ seen: Bool) -> Results<UserStatuses> {
        let sortProperties = [SortDescriptor(keyPath: DBConstants.lastStatusTimestamp, ascending: false)]


        let currentUserFilterPredicate = NSPredicate(format: "NOT (\(DBConstants.statusUserId) IN %@)", [FireManager.getUid()])
//        let predicate = "\(DBConstants.lastStatusTimestamp) >= \(TimeHelper.getTimeBefore24Hours()) AND statuses.@count > 0"
        let seenFilter = "\(DBConstants.ARE_ALL_STATUSES_SEEN) = \(seen)"
        let predicate = "\(DBConstants.lastStatusTimestamp) >= \(TimeHelper.getTimeBefore24Hours()) AND statuses.@count > 0 "


        return uiRealm.objects(UserStatuses.self).filter(seenFilter).filter(currentUserFilterPredicate).filter(predicate)
            .sorted(by: sortProperties)
    }

    public func getStatus(statusId: String) -> Status? {
        return getStatuses(statusId: statusId).first
    }
    
    public func getStatuses(statusId: String) -> Results<Status> {
        return uiRealm.objects(Status.self).filter("\(DBConstants.statusId) == '\(statusId)'")
    }
    
    public func getUserStatuses(userId: String) -> UserStatuses? {
        return uiRealm.objects(UserStatuses.self).filter("\(DBConstants.statusUserId) == '\(userId)' AND statuses.@count > 0").first
    }

    public func saveStatus(userId: String, status: Status) {


        guard let user = getUser(uid: userId) else {
            return
        }


        let userStatuses = getUserStatuses(userId: userId)

        openTransaction {

            if let userStatuses = userStatuses {
                let statuses = userStatuses.statuses
                if !statuses.contains(status) {
                    statuses.append(status)
                    userStatuses.lastStatusTimestamp = status.timestamp
                    userStatuses.user = user
                    userStatuses.areAllSeen = false
                }

            } else {
                let userStatuses = UserStatuses()
                userStatuses.userId = userId
                userStatuses.lastStatusTimestamp = status.timestamp
                let statuses = userStatuses.statuses
                statuses.append(status)
                userStatuses.user = user
                userStatuses.statuses = statuses
                uiRealm.add(userStatuses, update: .modified)
            }
        }
    }

    public func setLocalPathForVideoStatus(statusId: String, path: String) {
        if let status = getStatus(statusId: statusId) {
            openTransaction {
                status.localPath = path
            }
        }
    }

    public func deleteStatus(userId: String, statusId: String) {
        guard let userStatuses = getUserStatuses(userId: userId), let status = getStatus(statusId: statusId) else {
            return
        }

        openTransaction {
            let statuses = userStatuses.statuses

            if status.localPath != "" {
                do {
                    try URL(fileURLWithPath: status.localPath).deleteFile()
                } catch {

                }
            }

            if let index = statuses.index(of: status) {
                userStatuses.statuses.remove(at: index)
                uiRealm.delete(status)
            }

        }
    }

    public func setStatusAsSeen(statusId: String) {
        guard let status = getStatus(statusId: statusId) else {
            return
        }

        openTransaction {
            status.isSeen = true
        }


    }

    public func setAllStatusesAsSeen(userId: String) {
        guard let userStatuses = getUserStatuses(userId: userId) else {
            return
        }

        openTransaction {
            userStatuses.areAllSeen = true
        }

    }
    
    func setStatusSeenCount(statusId:String,count:Int){
        if let status = getStatus(statusId: statusId){
            openTransaction {
                status.seenCount = count
            }
        }
    }

    public func deleteExpiredStatuses() {
        let results = uiRealm.objects(Status.self)
            .filter("\(DBConstants.TIMESTAMP) <= \(TimeHelper.getTimeBefore24Hours())")


        for status in results {
            deleteStatus(userId: status.userId, statusId: status.statusId)
        }
    }

    public func getCalls() -> Results<FireCall> {
        return uiRealm.objects(FireCall.self)
            .sorted(byKeyPath: DBConstants.TIMESTAMP, ascending: false)
    }

    public func searchForCall(text: String) -> Results<FireCall> {
        return getCalls().filter("\(DBConstants.USER_USERNAME) contains[cd] '\(text)'")
    }

    public func getFireCall(callId: String) -> FireCall? {
        return uiRealm.objects(FireCall.self).filter("\(DBConstants.CALL_ID) == '\(callId)'").first
    }
    
    public func getFireCallByUUID(callUUID: String) -> FireCall? {
          return uiRealm.objects(FireCall.self).filter("\(DBConstants.CALL_UUID) == '\(callUUID)'").first
      }
    
    public func setCallDirection(callId: String, callDirection: CallDirection) {
        if let fireCall = getFireCall(callId: callId) {
            openTransaction {
                fireCall.callDirection = callDirection
            }
        }
    }

    public func updateCallInfoOnCallEnded(callId: String, duration: Int) {
        if let fireCall = getFireCall(callId: callId) {
            openTransaction {
                fireCall.duration = duration
            }
        }
    }

    public func isCallCancelled(callId: String) -> Bool {

        if let call = getFireCall(callId: callId) {
            return call.callDirection == .MISSED
        }

        return false


    }
    
    func deleteFireCall(callId:String){
        if let call = getFireCall(callId: callId){
            openTransaction {
                uiRealm.delete(call)
            }
        }
    }


    public func changeUserName(userName: String) {

        if let user = getUser(uid: FireManager.getUid()) {
            openTransaction {
                user.userName = userName
            }
        }



    }

    public func changeMyStatus(status: String) {

        if let user = getUser(uid: FireManager.getUid()) {
            openTransaction {
                user.status = status
            }
        }



    }

    public func getObservableList(chatId: String) -> Results<Message> {
        return getMessagesInChat(chatId: chatId).filter("\(DBConstants.MESSAGE_STAT) != \(MessageState.READ.rawValue)")
    }

    public func getUnreadAndUnDeliveredSentMessages(chatId: String, senderId: String) -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.CHAT_ID) == '\(chatId)' AND \(DBConstants.FROM_ID) == '\(senderId)' AND ( \(DBConstants.MESSAGE_STAT) == \(MessageState.SENT.rawValue) OR \(DBConstants.MESSAGE_STAT) == \(MessageState.RECEIVED.rawValue))")

    }


    public func setMessagesAsReadLocally(chatId: String) {



        let unreadMessages = uiRealm.objects(Message.self).filter("\(DBConstants.CHAT_ID) == '\(chatId)' AND \(DBConstants.FROM_ID) != '\(FireManager.getUid())' AND \(DBConstants.TYPE) != \(MessageType.GROUP_EVENT.rawValue) AND \(DBConstants.TYPE) != \(MessageType.DATE_HEADER.rawValue) AND \(DBConstants.MESSAGE_STAT) != \(MessageState.READ.rawValue) ")


        openTransaction {
            for unreadMessage in unreadMessages {
                unreadMessage.messageState = .READ
            }
        }

    }

    //get received messages that are not read to update them in Firebase database as read
    public func getUnReadIncomingMessages(chatId: String) -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.CHAT_ID) == '\(chatId)' AND \(DBConstants.FROM_ID) != '\(FireManager.getUid())' AND \(DBConstants.MESSAGE_STAT) != \(MessageState.READ.rawValue)")

    }

    //get not sent messages to send them when internet is available
    public func getPendingMessages() -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.TYPE) != \(MessageType.GROUP_EVENT.rawValue) AND \(DBConstants.TYPE) != \(MessageType.DATE_HEADER.rawValue) AND \(DBConstants.MESSAGE_STAT) == \(MessageState.PENDING.rawValue) AND \(DBConstants.DOWNLOAD_UPLOAD_STAT) != \(DownloadUploadState.CANCELLED.rawValue)")
    }

    public func getUnProcessedNetworkRequests() -> Results<Message> {


//
//        return uiRealm.objects(Message.self).filter("\(DBConstants.FROM_ID) == '\(FireManager.getUid())' AND \(DBConstants.DOWNLOAD_UPLOAD_STAT) == \(DownloadUploadState.LOADING.rawValue) OR \(DBConstants.FROM_ID) == '\(FireManager.getUid())' AND \(DBConstants.MESSAGE_STAT) == \(MessageState.PENDING.rawValue) AND \(DBConstants.MESSAGE_STAT) != \(MessageState.NONE.rawValue) ")
        
//        return uiRealm.objects(Message.self).filter("\(DBConstants.DOWNLOAD_UPLOAD_STAT) == \(DownloadUploadState.LOADING.rawValue) OR (\(DBConstants.TYPE) == \(MessageType.SENT_TEXT.rawValue) AND \(DBConstants.MESSAGE_STAT) == \(MessageState.PENDING.rawValue))")
        
         return uiRealm.objects(Message.self).filter("\(DBConstants.DOWNLOAD_UPLOAD_STAT) == \(DownloadUploadState.LOADING.rawValue)")
    }

    public func getUnReadVoiceMessages(chatId: String) -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.CHAT_ID) == '\(chatId)' AND \(DBConstants.TYPE) == \(MessageType.SENT_VOICE_MESSAGE.rawValue) AND \(DBConstants.VOICE_MESSAGE_SEEN) != true")
    }

    public func setVideoThumb(messageId: String, chatId: String, videoThumb: String) {
        if let message = getMessage(messageId: messageId) {
            openTransaction {
                message.videoThumb = videoThumb
            }
        }
    }

    //this will update the group, add,remove a user,set a user as an admin,
    //check for group info change,etc..
    public func updateGroup(groupId: String, info: DataSnapshot, usersSnapshot: DataSnapshot) -> [String]? {

        guard let groupUser = getUser(uid: groupId), let group = groupUser.group else { return nil }
        
        let post = info.childSnapshot(forPath: "onlyAdminsCanPost").value
        
        guard let onlyAdminsCanPost = info.childSnapshot(forPath: "onlyAdminsCanPost").value else{
            return nil
        }
        let groupName = info.childSnapshot(forPath: "name").value as! String
        let thumbImg = info.childSnapshot(forPath: "thumbImg").value as! String

        let users = group.users
        let adminsUids = group.adminUids

        var unfetchedUsers = [String]()

        var serverUids = [String]()
        var storedUids = [String]()

        storedUids = group.users.map { $0.uid }

        openTransaction {

            if group.onlyAdminsCanPost != onlyAdminsCanPost as! Bool {
                group.onlyAdminsCanPost = onlyAdminsCanPost as! Bool
            }

            if groupUser.userName != groupName {
                groupUser.userName = groupName
            }

            if groupUser.thumbImg != thumbImg {
                groupUser.thumbImg = thumbImg
            }

            let enumerator = usersSnapshot.children

            while let dataSnapshot = enumerator.nextObject() as? DataSnapshot {

                let uid = dataSnapshot.key
                let isAdmin = dataSnapshot.value as! Bool
                serverUids.append(uid)

                if (isAdmin) {
                    if (!adminsUids.contains(uid)) {
                        adminsUids.append(uid)
                    }
                } else {
                    if (adminsUids.contains(uid)) {

                        if let index = adminsUids.firstIndex(of: uid) {
                            adminsUids.remove(at: index)
                        }
                    }
                }


            }

            //get only unique items from two lists and act against it
            let distinctArr = storedUids + serverUids
            let distinct = distnictTwoArrays(storedUids, serverUids)


            for uid in distinct {
                //addition event
                if serverUids.contains(uid) {
                    if let user = getUser(uid: uid) {
                        users.append(user);
                        if usersSnapshot.childSnapshot(forPath: uid).value as! Bool {
                            adminsUids.append(uid)
                        }
                    } else {
                        //if it's a new user then add him to hashmap to fetch his data late
                        unfetchedUsers.append(uid)
                    }

                    //if the uid is current user's id then set the group as active
                    if uid == FireManager.getUid() {
                        group.isActive = true

                    }
                }
                //otherwise it's a deletion event
                    else {
                        //get user from group
                        if let user = users.filter({ $0.uid == uid }).first
                            , let index = users.firstIndex(of: user) {
                            //check if exists

                            //remove him from group
                            users.remove(at: index);
                            //if current user is removed set group active to false
                            if uid == FireManager.getUid() {
                                group.isActive = false
                                SwiftEventBus.post(EventNames.groupActiveStateChanged, sender: GroupActiveStateChanged(groupId: group.groupId, isActive: false))

                            }
                        }
                }
            }

        }
        return unfetchedUsers;
    }
    func distnictTwoArrays(_ array1: [String], _ array2: [String]) -> [String] {
        // Prepare a union
        var union = array1 + array2



        // Prepare an intersection
        var intersection = [String]()
        intersection.append(contentsOf: array1)

        intersection = Array(Set(array1).intersection(Set(array2)))
        // Subtract the intersection from the union
        union.removeAll { intersection.contains($0) }


        return union
    }


    public func getMessageAndUpdateIt(messageId: String, messageCallback: MessageCallback) {
        let message = getMessage(messageId: messageId)
        openTransaction {
            messageCallback(message)
        }
    }


    public func exitGroup(groupId: String) {
        guard let groupUser = getUser(uid: groupId), let group = groupUser.group else {
            return
        }


        openTransaction {
            group.isActive = false
            group.adminUids.removeAll()
            if let user = group.users.filter({ $0.uid == FireManager.getUid() }).first, let index = group.users.firstIndex(of: user) {
                group.users.remove(at: index)
            }
        }


    }
    
    public func getUnreadChats() -> Results<Chat> {
        return uiRealm.objects(Chat.self)
            .filter("\(DBConstants.UNREAD_COUNT) != 0")
            .filter("\(DBConstants.isMuted) != true")
            .sorted(byKeyPath: DBConstants.CHAT_LAST_MESSAGE_TIMESTAMP, ascending: true)
    }

    public func getUnUpdatedVoiceMessages() -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.voiceMessageNeedsToUpdateState) == true")
    }
    public func getUnReadReceivedMessages(chatId: String) -> Results<Message> {
        return getMessagesInChat(chatId: chatId).filter("\(DBConstants.FROM_ID) != '\(FireManager.getUid())' AND \(DBConstants.MESSAGE_STAT) != \(MessageState.READ.rawValue)")
    }

    public func getUnReadReceivedMessages() -> Results<Message> {
        return uiRealm.objects(Message.self).filter("\(DBConstants.FROM_ID) != '\(FireManager.getUid())' AND \(DBConstants.MESSAGE_STAT) != \(MessageState.READ.rawValue) AND \(DBConstants.isGroupBool) == false")
    }


    public func getUnUpdatedStates() -> Results<UnUpdatedMessageState> {
        return uiRealm.objects(UnUpdatedMessageState.self)
    }


    public func deleteUnUpdatedState(messageId: String) {
        let messages = uiRealm.objects(UnUpdatedMessageState.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'")
        openTransaction {
            uiRealm.delete(messages)
        }
    }
    //set message as deleted (Delete for everyone)
    public func setMessageDeleted(messageId: String) {
        let messages = getMessages(messageId: messageId)

        if messages.isEmpty {
            saveDeletedMessage(messageId: messageId)
            return
        }

        openTransaction {
            for message in messages {
                //if it's already deleted(if it's in group the delete event occurred twice)
                let type = message.typeEnum
                if !type.isDeletedMessage() {


                    if type.isMediaType()  {
                        URL(fileURLWithPath: message.localPath).deleteFileNotThrows()
                        message.localPath = ""
                    }

                    if type.isSentType() {
                        message.typeEnum = .SENT_DELETED_MESSAGE
                    }
                    else {
                        message.typeEnum = .RECEIVED_DELETED_MESSAGE
                    }
                    message.messageState = .NONE

                    let chatId = message.chatId
                    deleteDeletedMessage(messageId: messageId)

                }
            }
        }
    }

    public func saveDeletedMessage(messageId: String) {
        let deletedMessage = DeletedMessage(messageId: messageId)
        saveObjectToRealm(object: deletedMessage)
    }

    public func getDeletedMessage(messageId: String) -> DeletedMessage? {
        return uiRealm.objects(DeletedMessage.self).filter("\(DBConstants.MESSAGE_ID) ==  '\(messageId)'").first
    }

    private func deleteDeletedMessage(messageId: String) {
        if let deletedMessage = getDeletedMessage(messageId: messageId) {

            uiRealm.delete(deletedMessage)

        }
    }

    public func updateUserObjectForCall(uid: String, callId: String) {
        guard let user = getUser(uid: uid), let
        fireCall = getFireCall(callId: callId) else { return }


        openTransaction {
            fireCall.user = user
        }


    }

    public func setStatusSeenSent(statusId: String) {
        guard let status = getStatus(statusId: statusId) else { return }

        openTransaction {
            status.seenCountSent = true
        }

    }

    public func deleteUnProcessJobSeen(statusId: String) {
        if let unProcessJobSeen = getUnProcessedJobSeen(statusId: statusId) {
            openTransaction {
                uiRealm.delete(unProcessJobSeen)
            }
        }
    }



    public func getUnProcessedJobSeen(statusId: String) -> UnProcessedStatusSeen? {
        return uiRealm.objects(UnProcessedStatusSeen.self).filter("\(DBConstants.statusId) == '\(statusId)'").first
    }

    public func getUnProcessedJobsSeen() -> Results<UnProcessedStatusSeen> {
        return uiRealm.objects(UnProcessedStatusSeen.self)
    }


    public func saveUnProcessedJobSeen(uid: String, statusId: String) {
        if getUnProcessedJobSeen(statusId: statusId) != nil { return }

        let unProcessedStatusSeenJob = UnProcessedStatusSeen(statusId: statusId, uid: uid)

        saveObjectToRealm(object: unProcessedStatusSeenJob)
    }

    public func deleteDeletedStatusesLocally(statusesIds: [String]) {
        let statuses = getStatuses()


        for status in statuses {
            if !statusesIds.contains(status.statusId) {
                deleteStatus(userId: status.userId, statusId: status.statusId)
            }
        }
    }

    //update user info if it's different from stored user
    public func updateUserInfo(newUser: User, storedUser: User, name: String, isStored: Bool) {

        openTransaction {


            if storedUser.status != newUser.status {
                storedUser.status = newUser.status
            }

            if storedUser.userName != name {
                storedUser.userName = newUser.userName
            }

            if storedUser.thumbImg != newUser.thumbImg {
                storedUser.thumbImg = newUser.thumbImg
            }

            if storedUser.isStoredInContacts != isStored {
                storedUser.isStoredInContacts = isStored
            }

            if storedUser.appVer != newUser.appVer {
                storedUser.appVer = newUser.appVer
            }

        }

    }
    public func setIsStoredInContacts(user: User, isStored: Bool) {
        openTransaction {
            user.isStoredInContacts = isStored
        }
    }


    public func setNotificationCount(chatId: String, count: Int) {
        if let chat = getChat(id: chatId) {
            openTransaction {
                chat.unReadCount = count
            }
        }

    }
    
    func updateUserNameForUser(uid:String,userName:String){
        if let user = getUser(uid: uid){
            openTransaction {
                user.userName = userName
            }
        }
    }

    public func incrementNotificationCount(chatId: String) {
        if let chat = getChat(id: chatId) {
            openTransaction {
                chat.unReadCount += 1
            }
        }

    }

    public func getNotificationsByChatId(chatId: String) -> Results<Notifications> {
        return uiRealm.objects(Notifications.self).filter("chatId == '\(chatId)'")
    }

    public func getNotificationsByMessageId(messageId: String) -> Results<Notifications> {
        return uiRealm.objects(Notifications.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'")
    }


    public func saveNotificationId(chatId: String, notificationId: String, messageId: String = "") {
        let notification = Notifications(chatId: chatId, notificationId: notificationId, messageId: messageId)
        saveObjectToRealm(object: notification, update: false)
    }

    public func deleteNotificationsForChat(chatId: String) {
        let notifications = getNotificationsByChatId(chatId: chatId)
        openTransaction {
            uiRealm.delete(notifications)
        }

    }

    public func getUnsubscribedGroups() -> Results<Group> {
        return uiRealm.objects(Group.self).filter("subscribed == false")
    }

    public func setGroupSubscribed(groupId: String, bool: Bool) {
        if let group = uiRealm.objects(Group.self).filter("\(DBConstants.GROUP_ID) == '\(groupId)'").first {
            openTransaction {
                group.subscribed = bool
            }
        }
    }

    public func deletePendingGroupJob(groupId: String) {
        if let pendingGroupJob = uiRealm.objects(PendingGroupJob.self).filter("\(DBConstants.GROUP_ID) == '\(groupId)'").first {
            openTransaction {
                uiRealm.delete(pendingGroupJob)
            }
        }

    }

    public func getPendingGroupJobs() -> Results<PendingGroupJob> {
        return uiRealm.objects(PendingGroupJob.self)
    }


    public func getMediaToSave() ->Results<MediaToSave> {
        return uiRealm.objects(MediaToSave.self)

    }

    public func deleteMediaToSave() {
        let mediaToSave = getMediaToSave()
        openTransaction {
            uiRealm.delete(mediaToSave)
        }

    }
    public func setMessagesAsSeenLocally(chatId:String){
        let messages = getMessagesInChat(chatId: chatId).filter("\(DBConstants.IS_SEEN) == false")
        openTransaction {
            for message in messages{
                message.isSeen = true
            }
        }
    }
    
    public func saveSeenByList( statusId:String, seenByList: [StatusSeenBy]) {
        if let status = getStatus(statusId: statusId){
            openTransaction {
                let seenByRealmList = status.statusSeenBy
                for statusSeenBy in seenByList{
                    if !seenByRealmList.contains(statusSeenBy){
                        seenByRealmList.append(statusSeenBy)
                    }
                }
                status.seenCount = seenByList.count
                
                
            }
        }
       
       }
    
    public func getSeenByList( seenByList:List<StatusSeenBy>) -> Results<StatusSeenBy> {
        return seenByList.sorted(byKeyPath: "seenAt", ascending: false)
      }
    

    
    public func clearRealm(){
        try? uiRealm.safeWrite {
            uiRealm.deleteAll()
        }
    }
    
    public func setUserDeleted( userId:String,b:Bool) {
        if let user = getUser(uid: userId){
            try? uiRealm.safeWrite {
                 user.isDeleted = b
                user.userName = Strings.deleted
                 user.phone = ""
                 user.photo = ""
                 user.status = ""
                 user.thumbImg = ""
                 user.userLocalPhoto = ""
                 user.isStoredInContacts = false
             }
         }
     }
    
}
