//
//  FirebaseMessagingExtensions.swift
//  FireApp
//
//  Created by Devlomi on 2/9/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import FirebaseMessaging
import FirebaseInstanceID
import RxSwift

extension InstanceID{
    func getToken() -> Single<String> {
        return Single<String>.create { (observer) -> Disposable in
            InstanceID.instanceID().instanceID { (result, error) in
              if let error = error {
                observer(.error(error))
              } else if let result = result {
                observer(.success(result.token))
              }
            }
            
            return Disposables.create()
        }
    }
}

extension Messaging {
    func subscribeToTopicRx(topic: String) -> Single<Void> {
        return Single<Void>.create { (observer) -> Disposable in
            self.subscribe(toTopic: topic) { (error) in
                if let error = error {
                    observer(.error(error))
                } else {
                    
                    observer(.success(Void()))
                }
            }
            return Disposables.create()
        }

    }

    func unsubscribeFromTopicRx(topic: String) -> Single<Void> {
        return Single<Void>.create { (observer) -> Disposable in
            self.unsubscribe(fromTopic: topic) { (error) in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.success(Void()))
                }
            }
            return Disposables.create()
        }

    }
}
