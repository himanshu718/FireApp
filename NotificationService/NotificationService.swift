//
//  NotificationService.swift
//  NotificationService
//
//  Created by Devlomi on 2/8/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UserNotifications
import RealmSwift
import RxSwift
import Firebase

private let fileURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: Config.groupName)!
    .appendingPathComponent("default.realm")
private let config = RealmConfig.getConfig(fileURL: fileURL, objectTypes:
                                            [Message.self, Chat.self, User.self, DeletedMessage.self, RealmLocation.self, RealmContact.self, PhoneNumber.self, QuotedMessage.self, Group.self, Broadcast.self, Notifications.self, GroupEvent.self, PendingGroupJob.self, UnUpdatedMessageState.self, FireCall.self, MediaToSave.self,Status.self,StatusSeenBy.self,TextStatus.self,TempMessage.self
        ])

let appRealm = try! Realm(configuration: config)
let disposeBag = DisposeBag()

class NotificationService: UNNotificationServiceExtension {
    let newMessageHandler = NewMessageHandler(downloadManager: DownloadManager(disposeBag: disposeBag), messageDecryptor: MessageDecryptor(decryptionHelper: DecryptionHelper()))



    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?


    fileprivate func requestNewNotifications() {
        guard UserDefaultsManager.isAppInBackground() else {
            return
        }


        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {


            if let lastDate = UserDefaultsManager.getLastRequestUnDeliveredMessagesTime() {

                if TimeHelper.canRequestUnDeliveredNotifications(lastRequestTime: lastDate) {

                    MessageManager.requestForNewNotifications(disposeBag: disposeBag)
                }
            } else {

                MessageManager.requestForNewNotifications(disposeBag: disposeBag)
            }

        }
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)


        if let bestAttemptContent = bestAttemptContent {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }

            if !FireManager.isLoggedIn {
                return
            }


            DispatchQueue.main.async {
                let userInfo = bestAttemptContent.userInfo
                let notificationName = UserDefaultsManager.getRingtoneFileName()
                let notificationSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: notificationName))
                bestAttemptContent.sound = notificationSound

                let isAppInBackground = UserDefaultsManager.isAppInBackground()

                if let event = userInfo["event"] as? String {
                    if event == "new_group" {
                        if let groupId = userInfo["groupId"] as? String {
                            if isAppInBackground {
                                MessageManager.deleteNewGroupEvent(groupId: groupId).subscribe().disposed(by: disposeBag)
                                self.handleNewGroup(userInfo, bestAttemptContent: bestAttemptContent)
                            } else {
                                contentHandler(bestAttemptContent)
                            }

                        }


                        self.requestNewNotifications()
                    } else if event == "message_deleted" {
                        if let messageId = userInfo["messageId"] as? String {

                            if isAppInBackground {
                                MessageManager.deleteDeletedMessage(messageId: messageId).subscribe().disposed(by: disposeBag)

                                self.handleDeletedMessage(messageId, bestAttemptContent: bestAttemptContent)
                            } else {
                                contentHandler(bestAttemptContent)
                            }
                            self.requestNewNotifications()

                        }
                    }else if event == "logout"{
//                        if let newDeviceId = userInfo["deviceId"] as? String, newDeviceId != DeviceId.id{
//                            FireManager.logout()
//                        }
//                        bestAttemptContent.title = Strings.logged_out
//                        bestAttemptContent.body = Strings.logged_out_message
//                        contentHandler(bestAttemptContent)
                    }
                } else if let messageId = userInfo["messageId"] as? String {
                    if isAppInBackground {
                        self.handleNewMessage(userInfo, messageId, request: request, bestAttemptContent: bestAttemptContent)

                    } else {
                        //just a fallback solution in case anything wrong hanppened
                        if let message = RealmHelper.getInstance(appRealm).getMessage(messageId: messageId), let user = RealmHelper.getInstance(appRealm).getUser(uid: message.chatId) {
                            bestAttemptContent.title = GetUserInfo.getUserName(user: user, fromId: message.fromId, fromPhone: message.fromPhone)
                            bestAttemptContent.body = MessageTypeHelper.getMessageContent(message: message, includeEmoji: true)
                            bestAttemptContent.threadIdentifier = message.chatId
                            bestAttemptContent.userInfo["chatId"] = message.chatId
                            contentHandler(bestAttemptContent)
                        } else {
                            contentHandler(bestAttemptContent)
                        }
                    }




                    self.requestNewNotifications()

                }
            }


        } else {

        }
    }

    fileprivate func handleGroupEvent(_ userInfo: [AnyHashable: Any], bestAttemptContent: UNMutableNotificationContent) {

        if let groupId = userInfo["groupId"] as? String,
            let eventId = userInfo["eventId"] as? String, let contextStart = userInfo["contextStart"] as? String, let eventTypeStr = userInfo["eventType"] as? String, let contextEnd = userInfo["contextEnd"] as? String {

            let eventTypeInt = Int(eventTypeStr) ?? 0

            let eventType = GroupEventType(rawValue: eventTypeInt) ?? .UNKNOWN
            //if this event was by the admin himself  OR if the event already exists do nothing
            if contextStart != FireManager.number! && RealmHelper.getInstance(appRealm).getMessage(messageId: eventId) == nil {
                let groupEvent = GroupEvent(contextStart: contextStart, type: eventType, contextEnd: contextEnd)

                let pendingGroupJob = PendingGroupJob(groupId: groupId, type: eventType, event: groupEvent)
                RealmHelper.getInstance(appRealm).saveObjectToRealm(object: pendingGroupJob)
                GroupManager.updateGroup(groupId: groupId, groupEvent: groupEvent).subscribe(onCompleted: {

                    if let group = RealmHelper.getInstance(appRealm).getUser(uid: groupId)?.group {
                        bestAttemptContent.title = GroupEvent.extractString(messageContent: groupEvent.contextStart, users: group.users)

                        self.contentHandler?(bestAttemptContent)

                    }


                }).disposed(by: disposeBag)
            }
        }
    }

    fileprivate func handleNewGroup(_ userInfo: [AnyHashable: Any], bestAttemptContent: UNMutableNotificationContent) {

        NewNotificationsHandler(disposeBag: disposeBag).handleNewGroup(userInfo: userInfo).subscribe(onSuccess: { (notificationContent) in
            bestAttemptContent.title = notificationContent.title
            bestAttemptContent.body = notificationContent.body
            if let groupId = userInfo["groupId"] as? String {
                bestAttemptContent.threadIdentifier = groupId
            }
            self.contentHandler?(bestAttemptContent)
        }) { (error) in

        }.disposed(by: disposeBag)
    }

    fileprivate func handleDeletedMessage(_ messageId: String, bestAttemptContent: UNMutableNotificationContent) {
        let notificationsIds = Array(RealmHelper.getInstance(appRealm).getNotificationsByMessageId(messageId: messageId).map { $0.notificationId })
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationsIds)

        let notificationContent = NewNotificationsHandler(disposeBag: disposeBag).handleDeletedMessage(messageId: messageId)

        bestAttemptContent.title = notificationContent.title
        bestAttemptContent.body = notificationContent.body
        contentHandler?(bestAttemptContent)
    }

    fileprivate func handleNewMessage(_ userInfo: [AnyHashable: Any], _ messageId: String, request: UNNotificationRequest, bestAttemptContent: UNMutableNotificationContent) {

        let isAppInBackground = UserDefaultsManager.isAppInBackground()


        newMessageHandler.handleNewMessage(userInfo: userInfo, disposeBag: disposeBag, isSeen: !isAppInBackground, complete: {
            if let message = RealmHelper.getInstance(appRealm).getMessage(messageId: messageId), let user = RealmHelper.getInstance(appRealm).getUser(uid: message.chatId) {
                
                
                MessageManager.deleteMessage(messageId: messageId).subscribe().disposed(by: disposeBag)


                if isAppInBackground {
                    let badge = BadgeManager.incrementBadgeByOne(chatId: message.chatId)

                    bestAttemptContent.badge = badge as NSNumber

                    let unUpdatedState = UnUpdatedMessageState(messageId: messageId, myUid: FireManager.getUid(), chatId: message.chatId, statToBeUpdated: .RECEIVED)

                    RealmHelper.getInstance(appRealm).saveObjectToRealm(object: unUpdatedState, update: true)
                }

                let notificationId = request.identifier
                RealmHelper.getInstance(appRealm).saveNotificationId(chatId: message.chatId, notificationId: notificationId, messageId: messageId)
                bestAttemptContent.title = GetUserInfo.getUserName(user: user, fromId: message.fromId, fromPhone: message.fromPhone)
                bestAttemptContent.body = MessageTypeHelper.getMessageContent(message: message, includeEmoji: true)
                bestAttemptContent.threadIdentifier = message.chatId
                bestAttemptContent.userInfo["chatId"] = message.chatId

                self.contentHandler?(bestAttemptContent)
            }
        })
    }
    
    override func serviceExtensionTimeWillExpire() {

        UserDefaultsManager.setFetchingUnDeliveredMessages(bool: false)

        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
