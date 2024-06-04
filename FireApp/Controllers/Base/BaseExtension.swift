//
//  BaseExtension.swift
//  FireApp
//
//  Created by Devlomi on 2/29/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import SwiftEventBus
import NotificationView

extension Base where Self: UIViewController {
    internal func handleNewMessageNotification() {

        SwiftEventBus.onMainThread(self, name: EventNames.newMessageReceived) { event in
            guard let data = event?.object as? (Message, User) else {
                return
            }

            let message = data.0
            let user = data.1


            guard message.chatId != AppDelegate.shared.currentChatId else {
                return
            }

            let isMuted = RealmHelper.getInstance(appRealm).getChat(id: user.uid)?.isMuted ?? false

            if !isMuted && UserDefaultsManager.areNotificationsOn() {
                let notificationView = NotificationView.default

                notificationView.title = GetUserInfo.getUserName(user: user, fromId: message.fromId, fromPhone: message.fromPhone)
                notificationView.subtitle = nil
                notificationView.body = MessageTypeHelper.getMessageContent(message: message, includeEmoji: true)
                let image = user.thumbImg.isEmpty ? UIImage(named: "profile") : user.thumbImg.toUIImage()
                notificationView.image = image
                notificationView.date = TimeHelper.getTimeOnly(date: message.timestamp.toDate())
                notificationView.identifier = message.chatId
                notificationView.delegate = self.notificationDelegate

                notificationView.show()

            }




            let badge = BadgeManager.incrementBadgeByOne(chatId: message.chatId)
            UIApplication.shared.applicationIconBadgeNumber = badge



        }

        SwiftEventBus.onMainThread(self, name: EventNames.newGroupCreated) { (event) in
            guard let groupUser = event?.object as? User else {
                return
            }

            let notificationView = NotificationView.default

            notificationView.title = groupUser.userName
            notificationView.subtitle = nil
            notificationView.body = Strings.new_group
            let image = groupUser.thumbImg.isEmpty ? UIImage(named: "profile") : groupUser.thumbImg.toUIImage()
            notificationView.image = image
            notificationView.identifier = groupUser.uid
            notificationView.delegate = self.notificationDelegate

            notificationView.show()

        }


        SwiftEventBus.onMainThread(self, name: EventNames.messageDeleted) { (event) in
            guard let tuple = event?.object as? (Message, User) else {
                return
            }

            let message = tuple.0
            let user = tuple.1

            guard message.chatId != AppDelegate.shared.currentChatId else {
                return
            }

            let isMuted = RealmHelper.getInstance(appRealm).getChat(id: user.uid)?.isMuted ?? false

            if !isMuted && UserDefaultsManager.areNotificationsOn() {

                let notificationView = NotificationView.default

                notificationView.title = GetUserInfo.getUserName(user: user, fromId: message.fromId, fromPhone: message.fromPhone)
                notificationView.subtitle = nil
                notificationView.body = Strings.this_message_deleted
                let image = user.thumbImg.isEmpty ? UIImage(named: "profile") : user.thumbImg.toUIImage()
                notificationView.image = image
                notificationView.identifier = user.uid
                notificationView.delegate = self.notificationDelegate

                notificationView.show()
            }
        }

        SwiftEventBus.onMainThread(self, name: EventNames.missedCall) { (event) in
            guard let user = event?.object as? User else {
                return
            }



            let notificationView = NotificationView.default

            notificationView.title = user.userName
            notificationView.subtitle = nil
            notificationView.body = Strings.missed_call
            let image = user.thumbImg.isEmpty ? UIImage(named: "profile") : user.thumbImg.toUIImage()
            notificationView.image = image
            notificationView.identifier = user.uid
            notificationView.delegate = self.notificationDelegate

            notificationView.show()

        }
    }
    //handle system notification tap
    func handleNotificationTap() {
        SwiftEventBus.onMainThread(self, name: EventNames.notificationTapped) { event in
            guard let chatId = event?.object as? String, let user = RealmHelper.getInstance(appRealm).getUser(uid: chatId) else {
                return
            }


            self.goToChatVC(user: user, isSystemNotification: true)

        }
    }

    func handleGroupLinkTap() {
        SwiftEventBus.onMainThread(self, name: EventNames.groupLinkTapped) { (event) in
            guard let groupLink = event?.object as? String else { return }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            if let groupInfoPreviewVC = storyboard.instantiateViewController(withIdentifier: "groupInfoPreview") as? GroupInfoPreviewVC {
                groupInfoPreviewVC.initialize(groupLink: groupLink)

                self.present(groupInfoPreviewVC, animated: true, completion: nil)
            }
        }
    }



    private func goToChatVC(user: User, isSystemNotification: Bool) {


        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController

        let tabBarVC = self.storyboard?.instantiateViewController(withIdentifier: "tabBarVC") as! TabBarVC

        vc.initialize(user: user)

        navigationController?.viewControllers = [tabBarVC]


        //wait for the VC to load up and then push it using navigation
        if isSystemNotification {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                tabBarVC.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            tabBarVC.navigationController?.pushViewController(vc, animated: true)
        }
    }

    //handle in app notification view tap
    func swizzledNotificationViewDidTap(_ notificationView: NotificationView) {

        let chatId = notificationView.identifier
        if let user = RealmHelper.getInstance(appRealm).getUser(uid: chatId) {
            goToChatVC(user: user, isSystemNotification: false)

        }
    }

    func handleUnRegisterEvents() {
        SwiftEventBus.unregister(self)
    }

}



