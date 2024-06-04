//
//  UserByIdDataSource.swift
//  FireApp
//
//  Created by Devlomi on 3/17/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import RxSwift
class UserByIdDataSource {
    static func getUsersByIds(uids:[String]) -> Observable<[User]>  {
        var observers = [Observable<User>]()
        
        for uid in uids{
            if uid != FireManager.getUid(){
                if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid){
                    observers.append(Observable.just(user))
                }else{
                    observers.append(FireManager.fetchUserByUid(uid: uid, appRealm: appRealm))
                }
            }
        }
        return Observable.from(observers).merge().toArray().asObservable()
        
    }
}
