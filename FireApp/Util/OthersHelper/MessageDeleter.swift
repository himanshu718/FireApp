//
//  MessageDeleter.swift
//  FireApp
//
//  Created by Devlomi on 3/15/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase
import RealmSwift

class MessageDeleter {
    public static func deleteMessagesForEveryone(messages: [Message], user: User, appRealm: Realm) -> Observable<DatabaseReference> {
         return FireManager.getServerTime().flatMap { serverTime in

             return Observable.from(messages).asObservable().flatMap { message -> Observable<DatabaseReference> in
                 if !TimeHelper.isMessageTimePassed(serverTime: serverTime, messageTime: message.timestamp.toDate()) {
                     return FireConstants.getDeleteMessageRequestsRef(messageId: message.messageId, isGroup: user.isGroupBool, isBroadcast: user.isGroupBool, groupOrBroadcastId: user.uid).rx.setValue(true).asObservable().do(onCompleted: {
                         if message.downloadUploadState == .LOADING {
                             if message.typeEnum.isSentType() {
                                 UploadManager.cancelUpload(message: message, appRealm: appRealm)
                             } else {
                                 RequestManager.cancelDownload(message: message, appRealm: appRealm)
                             }
                         }

                         RealmHelper.getInstance(appRealm).setMessageDeleted(messageId: message.messageId)

                     })

                 } else {
                     return Observable.empty()
                 }
             }
         }

     }
}
