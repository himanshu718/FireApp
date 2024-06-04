//
//  MessageManager.swift
//  FireApp
//
//  Created by Devlomi on 3/23/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth
import FirebaseFunctions
import RxFirebase
import RxSwift
import RealmSwift

class MessageManager {

    static func deleteMessage(messageId: String) -> Single<DatabaseReference> {
        return FireConstants.userMessages.child(FireManager.getUid()).child(messageId).rx.removeValue()
    }
    
    static func deleteMissedCall(callId: String) -> Single<DatabaseReference> {
        return FireConstants.missedCalls.child(FireManager.getUid()).child(callId).rx.removeValue()
      }
    
    static func deleteNewGroupEvent(groupId: String) -> Single<DatabaseReference> {
      return FireConstants.mainRef.child("newGroups").child(FireManager.getUid()).child(groupId).rx.removeValue()
    }
    
    static func deleteDeletedMessage(messageId: String) -> Single<DatabaseReference> {
         return FireConstants.mainRef.child("deletedMessages").child(FireManager.getUid()).child(messageId).rx.removeValue()
       }

    
    static func requestForNewNotifications(disposeBag:DisposeBag){
        UserDefaultsManager.setLastRequestUnDeliveredMessagesTime(date: Date())
        Functions.functions().httpsCallable("sendUnDeliveredNotifications").rx.call().subscribe(onNext: { (callableResult) in
            
        }, onError: { (error) in
            UserDefaultsManager.setFetchingUnDeliveredMessages(bool: false)

        
        }).disposed(by: disposeBag)
    }

}
