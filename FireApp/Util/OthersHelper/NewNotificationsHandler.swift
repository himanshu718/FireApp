//
//  NewNotificationsListeners.swift
//  FireApp
//
//  Created by Devlomi on 3/27/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth
import FirebaseFunctions
import RxFirebase
import RxSwift
import RealmSwift

class NewNotificationsHandler {
    private var disposeBag: DisposeBag

    init(disposeBag: DisposeBag) {
        self.disposeBag = disposeBag
    }


    func handleNewGroup(userInfo: [AnyHashable: Any]) -> Single<NotificationContent> {
        return Single.create { (observer) -> Disposable in
//            if !UserDefaultsManager.isUserInfoSaved(){
//                observer(.error(NSError(domain: "user data not saved ", code: 400, userInfo: nil)))
//
//                return Disposables.create()
//            }
            if let groupId = userInfo["groupId"] as? String, let groupName = userInfo["groupName"] as? String {

                let notificationContent = NotificationContent(title: Strings.new_group, body: Strings.you_added_to_group + " " + groupName)

                if let group = RealmHelper.getInstance(appRealm).getUser(uid: groupId)?.group {
                    let users = group.users
                    let contains = users.filter { $0.uid == FireManager.getUid() }.first != nil
                    //if the group is not active or the group does not contain current user
                    // then fetch and download it and set it as Active



                    if (!group.isActive || !contains) {
                        let pendingGroupJob = PendingGroupJob(groupId: groupId, type: .GROUP_CREATION, event: nil)
                        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: pendingGroupJob)
                        GroupManager.fetchAndCreateGroup(groupId: groupId, subscribeToTopic: false).subscribe(onCompleted: {
                            observer(.success(notificationContent))
                        }).disposed(by: self.disposeBag)
                    } else {
                        observer(.success(notificationContent))
                    }
                } else {
                    //if the group is not exists,fetch and download it
                    let pendingGroupJob = PendingGroupJob(groupId: groupId, type: .GROUP_CREATION, event: nil)
                    RealmHelper.getInstance(appRealm).saveObjectToRealm(object: pendingGroupJob)
                    GroupManager.fetchAndCreateGroup(groupId: groupId, subscribeToTopic: false).subscribe(onError: { error in
                    }, onCompleted: {
                            observer(.success(notificationContent))
                        }).disposed(by: self.disposeBag)
                }
            } else {
                observer(.error(NSError()))
            }
            return Disposables.create()
        }

    }
    func handleDeletedMessage(messageId: String) -> NotificationContent {
        RealmHelper.getInstance(appRealm).setMessageDeleted(messageId: messageId)

        if let message = RealmHelper.getInstance(appRealm).getMessage(messageId: messageId) {

            if message.downloadUploadState == .LOADING {
                DownloadManager.cancelDownload(message: message, appRealm: appRealm)
            }



            var title = ""
            if let chat = RealmHelper.getInstance(appRealm).getChat(id: message.chatId) {
                title = chat.user?.userName ?? message.fromPhone
            }
            let notificationContent = NotificationContent(title: title, body: Strings.this_message_deleted)

            return notificationContent
        }

        return NotificationContent(title: "", body: Strings.this_message_deleted)
    }

}

class NotificationContent: NSObject {
    var title: String = ""
    var body: String = ""

    init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
