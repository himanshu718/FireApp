//
//  NewNotificationsListeners.swift
//  FireApp
//
//  Created by Devlomi on 3/27/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseFunctions
import RxFirebase
import RxSwift
import RealmSwift

struct NewNotificationsListeners {
     let disposeBag: DisposeBag
     let newMessageHandler:NewMessageHandler
    
    func attachNewMessagesListeners() -> Observable<(Message, User)> {

        return Observable<(Message, User)>.create { (observer) -> Disposable in
            let childAddedObservable = FireConstants.userMessages.child(FireManager.getUid())
                .rx.observeEvent(.childAdded).subscribe(onNext: { (snapshot) in

                if snapshot.exists(), let dict = snapshot.value as? Dictionary<String, AnyObject>, let messageId = dict["messageId"] as? String {

                    newMessageHandler.handleNewMessage(userInfo: dict, disposeBag: self.disposeBag, isSeen: false) {

                        if let message = RealmHelper.getInstance(appRealm).getMessage(messageId: messageId),
                            let user = RealmHelper.getInstance(appRealm).getUser(uid: message.chatId) {
                            let event = (message, user)

                            observer.onNext(event)
                        }
                    }
                }
                
            })
            return Disposables.create{
                childAddedObservable.dispose()
            }
        }
    }

    func attachNewGroupListeners() -> Observable<User> {
        FireConstants.mainRef.child("newGroups").child(FireManager.getUid()).rx.observeEvent(.childAdded).flatMap { snapshot -> Observable<User> in
            if snapshot.exists(), let dict = snapshot.value as? Dictionary<String, AnyObject>, let groupId = dict["groupId"] as? String, let groupName = dict["groupName"] as? String {
                if let user = RealmHelper.getInstance(appRealm).getUser(uid: groupId), let group = user.group {
                    let users = group.users
                    let contains = users.filter { $0.uid == FireManager.getUid() }.first != nil

                    if (!group.isActive || !contains) {
                        let pendingGroupJob = PendingGroupJob(groupId: groupId, type: .GROUP_CREATION, event: nil)
                        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: pendingGroupJob)
                        return GroupManager.fetchAndCreateGroup(groupId: groupId, subscribeToTopic: false).flatMap { _ -> Observable<User> in
                            return Observable.from(optional: user)
                        }
                    } else {
                        return Observable.from(optional: user)
                    }
                } else {
                    //if the group is not exists,fetch and download it
                    let pendingGroupJob = PendingGroupJob(groupId: groupId, type: .GROUP_CREATION, event: nil)
                    RealmHelper.getInstance(appRealm).saveObjectToRealm(object: pendingGroupJob)
                    return GroupManager.fetchAndCreateGroup(groupId: groupId, subscribeToTopic: false)

                }
            } else {
                return Observable.empty()
            }
        }
    }

    func attachDeletedMessageListener() -> Observable<(Message, User)> {
        FireConstants.mainRef.child("deletedMessages").child(FireManager.getUid()).rx.observeEvent(.childAdded).flatMap { snapshot -> Observable<(Message, User)> in
            if snapshot.exists(), let dict = snapshot.value as? Dictionary<String, AnyObject>, let messageId = dict["messageId"] as? String {
                RealmHelper.getInstance(appRealm).setMessageDeleted(messageId: messageId)

                if let message = RealmHelper.getInstance(appRealm).getMessage(messageId: messageId) {

                    if message.downloadUploadState == .LOADING {
                        DownloadManager.cancelDownload(message: message, appRealm: appRealm)
                    }
                    if let chat = RealmHelper.getInstance(appRealm).getChat(id: message.chatId), let user = chat.user {
                        return Observable.from(optional: (message, user))
                    }
                }
            }
            return Observable.empty()
        }

    }

    /*
     since we are using PushKit for incoming calls we don't need this live events, therefore we delete them.
     */
    func attachNewCall() -> Observable<DatabaseReference> {
        return FireConstants.userCalls.child(FireManager.getUid()).rx.observeEvent(.childAdded).flatMap { $0.ref.rx.removeValue() }
    }
}
