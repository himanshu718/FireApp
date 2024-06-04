//
//  FCMTokenSaver.swift
//  FireApp
//
//  Created by Devlomi on 2/5/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import FirebaseDatabase
import FirebaseMessaging
import FirebaseInstanceID
import RxSwift

class FCMTokenSaver {

    private static func getToken() -> Single<String> {

        if !FireManager.isLoggedIn {
            return Single.error(NSError(domain: "user not authenticated", code: -90, userInfo: nil))
        }
        return InstanceID.instanceID().getToken()

    }


    //this will check if incoming token is null,that means to generate a new token
    //otherwise the token is coming from onNewToken and therefore just save it to database
    public static func saveTokenToFirebase(token: String?) -> Single<DatabaseReference> {
        if let token = token {
            return saveToken(token: token)
        } else {
            return getToken().flatMap { token in
                return saveToken(token: token)
            }
        }

    }

    public static func savePKTokenToFirebase(token:String) -> Single<DatabaseReference>{
        return FireConstants.usersRef.child(FireManager.getUid()).child("pktoken")
            .child(token).rx.setValue(true).do(onSuccess:{(_) in
                UserDefaultsManager.setPKTokenSaved(bool: true)
            },onError: {(error) in
                UserDefaultsManager.setPKTokenSaved(bool: false)
            })
    }


    private static func saveToken(token: String) -> Single<DatabaseReference> {
        return FireConstants.usersRef.child(FireManager.getUid()).child("notificationTokens")
            .child(token)
            .rx
            .setValue("ios")
            .do(onSuccess: { (_) in
                UserDefaultsManager.setTokenSaved(bool: true)
            }, onError: { (error) in
                    UserDefaultsManager.setTokenSaved(bool: false)
                })

    }
    
}
