//
//  RestoreDBMigration.swift
//  FireApp
//
//  Created by Devlomi on 4/12/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class RestoreDBMigration {

    func migrate(realmFile: URL) throws {
        let config = RealmConfig.getConfig(fileURL: realmFile)
        let realm = try Realm(configuration: config)


        let messages = realm.objects(Message.self)

        let chats = realm.objects(Chat.self)


        let groups = realm.objects(Group.self)

        let calls = realm.objects(FireCall.self)

        let broadcasts = realm.objects(Broadcast.self)

        try appRealm.safeWrite {

            for m in messages {
                //make a copy of it in memory so we can modify it
                let message = m.detached()
                //this is used to prevent duplicating messages
                //since quotedMessage DOES NOT have a primary key.
                var quotedMessageToSet: QuotedMessage? = nil
                /*
                this is used to save status, since
                realm.add() will copy ALL contents of a Message
                including a Status
                therefore if there were two quoted messages with statuses
                it will SAVE TWO STATUSES TO REALM AND THROW AN ERROR
                SINCE Status CANNOT BE UPDATED
                so we need to do the following:
                 1. check if there is a quoted message
                 if exists, set the #Message.QuotedMessage to nil
                 reference quotedMessage to add it later.
                 
                 2.if there is a status in quoted message, nullify it and referencet it
                 to statusToSet to add it later.
                 
                 3. add the message to realm
                 4. check if there is a need to set quoted message
                 5. check if there is a need to set a Status
                */
                var statusToSet: Status? = nil

                //update local path if needed
                if message.localPath != "" {

                    let folder = MediaBackupUtil.getFolderToZipByMediaType(mediaType: message.typeEnum)
                    //update local path
                    let url = URL(fileURLWithPath: message.localPath)
                    let newPath = folder.appendingPathComponent(url.lastPathComponent)

                    message.localPath = newPath.path

                } else {


                    if let quotedMessage = message.quotedMessage {

                        if let storedQuotedMessage = getQuotedMessage(messageId: quotedMessage.messageId) {
                            quotedMessageToSet = storedQuotedMessage
                            message.quotedMessage = nil

                        }

                        if let status = quotedMessage.status {
                            if let storedStatus = getStatus(statusId: status.statusId) {
                                statusToSet = storedStatus
                                message.quotedMessage?.status = nil
                            }
                        }

                    }

                }



                appRealm.add(message)
                if let quotedMessageToSet = quotedMessageToSet {
                    message.quotedMessage = quotedMessageToSet
                }
                if let statusToSet = statusToSet {
                    message.quotedMessage?.status = statusToSet
                }




            }


            for group in groups {
                appRealm.create(Group.self, value: group, update: .modified)
            }

            for c in chats {
                let chat = c.detached()
                let lastMessage = c.lastMessage?.detached()


                //set it to null to prevent duplicate messages, since they're already exists(while saving messages)
                chat.lastMessage = nil

                let savedChat = appRealm.create(Chat.self, value: chat, update: .modified)

                if let lastMessage = lastMessage {
                    //get last message from Messages and set it to this chat.
                    savedChat.lastMessage = getLastMessage(messageId: lastMessage.messageId, chatId: chat.chatId)
                }
            }

            for call in calls {
                appRealm.create(FireCall.self, value: call, update: .modified)
            }

            for broadcast in broadcasts {
                appRealm.create(Broadcast.self, value: broadcast, update: .modified)
            }

        }


    }
    private func getStatus(statusId: String) -> Status? {
        return appRealm.objects(Status.self).filter("\(DBConstants.statusId) == '\(statusId)'").first
    }

    private func getQuotedMessage(messageId: String) -> QuotedMessage? {
        return appRealm.objects(QuotedMessage.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'").first
    }

    public func getChat(id: String) -> Chat? {
        return appRealm.objects(Chat.self).filter("\(DBConstants.CHAT_ID) == '\(id)' ").first
    }

    private func getLastMessage(messageId: String, chatId: String) -> Message? {
        guard messageId.isNotEmpty else {
            return nil
        }


        return appRealm
            .objects(Message.self)
            .filter("\(DBConstants.MESSAGE_ID) == '\(messageId)' AND \(DBConstants.CHAT_ID) == '\(chatId)'")
            .first



    }
}
