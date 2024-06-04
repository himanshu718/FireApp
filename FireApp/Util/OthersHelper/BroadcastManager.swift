//
//  BroadcastManager.swift
//  FireApp
//
//  Created by Devlomi on 10/19/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import RxSwift
import FirebaseDatabase
import RealmSwift

class BroadcastManager {

    public static func createNewBroadcast(broadcastName: String, users: [User]) -> Single<User> {
        let broadcastId = FireConstants.broadcastsRef.childByAutoId().key!
        var result = [String: Any]()
        var broadcastInfo = [String: Any]()

        broadcastInfo[DBConstants.TIMESTAMP] = ServerValue.timestamp()
        broadcastInfo["createdBy"] = FireManager.number!

        let usersDict = User.toDict(userList: users, addCurrentUser: true)

        broadcastInfo["name"] = broadcastName
        result["info"] = broadcastInfo
        result["users"] = usersDict

        let observable = FireConstants.broadcastsRef.child(broadcastId).rx.setValue(result)

        return Single<User>.create { (observer) -> Disposable in
            observable.subscribe(onSuccess: { (_) in
                let broadcastUser = createBroadcastLocally(broadcastName: broadcastName, users: users, broadcastId: broadcastId, timestamp: CLong(Date().currentTimeMillis()))
                observer(.success(broadcastUser))
            }) { (error) in
                observer(.error(error))

            }
        }

    }

    private static func createBroadcastLocally(broadcastName: String, users: [User], broadcastId: String, timestamp: CLong) -> User {
        let broadcastUser = User()
        broadcastUser.userName = broadcastName
        broadcastUser.status = ""
        broadcastUser.phone = ""
        let list = List<User>()
        list.append(objectsIn: users)

        let broadcast = Broadcast()
        broadcast.broadcastId = broadcastId
        broadcast.users = list
        broadcast.timestamp = timestamp
        broadcast.createdByNumber = FireManager.number!
        broadcastUser.broadcast = broadcast
        broadcastUser.isBroadcastBool = true
        broadcastUser.uid = broadcastId
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: broadcastUser)
        RealmHelper.getInstance(appRealm).saveEmptyChat(user: broadcastUser)
        return broadcastUser
    }

    public static func deleteBroadcast(broadcastId: String) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            FireConstants.broadcastsRef.child(broadcastId).rx.removeValue().subscribe(onSuccess: { (_) in
                RealmHelper.getInstance(appRealm).deleteBroadcast(broadcastId: broadcastId)
                completable(.completed)
            }) { (error) in
                completable(.error(error))
            }

            return Disposables.create()
        })
    }

    public static func removeBroadcastMember(broadcastId: String, userToDeleteUid: String) -> Completable {
        return FireConstants.broadcastsRef.child(broadcastId).child("users").child(userToDeleteUid).rx.removeValue().asCompletable()
    }

    public static func updateBroadcastUsers(broadcastId: String, usersToRemoveUids: [String],usersToAddUids:[String],updatedLocalUsers:[User]) -> Completable {
        var dict = [String: Any]()
        
        for userToRemoveUid in usersToRemoveUids {
            dict[userToRemoveUid] = NSNull()//remove users
        }
        
        for userToAddUid in usersToAddUids {
            dict[userToAddUid] = false
        }

        return Completable.create(subscribe: { (completable) -> Disposable in
            FireConstants.broadcastsRef.child(broadcastId).child("users").rx.updateChildValues(dict).subscribe(onSuccess: { (_) in
                RealmHelper.getInstance(appRealm).updateBroadcastUsers(broadcastId: broadcastId, users: updatedLocalUsers)
                completable(.completed)
            }) { (error) in
                completable(.error(error))

            }
            return Disposables.create()
        })

    }

    public static func addParticipant(broadcastId: String, users: [User]) -> Completable {
        var dict = [String: Any]()
        for user in users {
            dict[user.uid] = false
        }

        return Completable.create(subscribe: { (completable) -> Disposable in
            FireConstants.broadcastsRef.child(broadcastId).child("users").rx.updateChildValues(dict).subscribe(onSuccess: { (_) in
                for user in users {
                    RealmHelper.getInstance(appRealm).addUserToBroadcast(broadcastId: broadcastId, user: user)
                }
                completable(.completed)
            }) { (error) in
                completable(.error(error))
            }

            return Disposables.create()

        })


    }

    public static func changeBroadcastName(broadcastId: String, newTitle: String) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in

            FireConstants.broadcastsRef.child(broadcastId).child("info").child("name").rx.setValue(newTitle).subscribe(onSuccess: { (_) in
                RealmHelper.getInstance(appRealm).changeBroadcastName(broadcastId: broadcastId, broadcastName: newTitle)
                completable(.completed)
            }) { (error) in
                completable(.error(error))
            }
            
            return Disposables.create()
        })

    }

    public static func fetchBroadcast(broadcastId: String) -> Single<String> {

        let observable = FireConstants.broadcastsRef.child(broadcastId).rx.observeSingleEvent(.value).asObservable().filter { $0.exists() }.flatMap { snapshot -> Observable<([User], DataSnapshot)> in

            let usersSnapshot = snapshot.childSnapshot(forPath: "users")

            let broadcastUserIds = getBroadcastUsersIds(usersSnapshot: usersSnapshot)

            let users = getUsersObservables(uids: broadcastUserIds)


            return users.map { ($0, snapshot) }
        }.map { users, snapshot in
            let info = snapshot.childSnapshot(forPath: "info")

            let broadcastName = info.childSnapshot(forPath: "name") .value as? String ?? ""
            let timestamp = info.childSnapshot(forPath: "timestamp") .value as? CLong ?? 0


            createBroadcastLocally(broadcastName: broadcastName, users: users, broadcastId: broadcastId, timestamp: timestamp)


        }
        return Single.create(subscribe: { (single) -> Disposable in
            observable.subscribe(onNext: nil, onError: { (error) in
                single(.error(error))
            }, onCompleted: {
                    single(.success(broadcastId))
                }, onDisposed: nil)
            return Disposables.create()
        })
    }


    private static func getBroadcastUsersIds(usersSnapshot: DataSnapshot) -> [String] {
        var uids = [String]()
        for snapshotItem in usersSnapshot.children.allObjects {
            let snapshot = snapshotItem as! DataSnapshot
            let uid = snapshot.key
            if uid != FireManager.getUid() {
                uids.append(uid)
            }
        }
        return uids
    }

    private static func getUsersObservables(uids: [String]) -> Observable<[User]> {
        var observersList = [Observable<User>]()



        for uid in uids {
            if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid) {
                observersList.append(Observable.from(optional: user))
            } else {
                observersList.append(FireManager.fetchUserByUid(uid: uid, appRealm: appRealm))
            }
        }

        let observables = Observable.from(observersList).merge().toArray().asObservable()




        return observables

    }

    public static func fetchBroadcasts(uid: String) -> Observable<[String]> {
        FireConstants.broadcastsByUser.child(uid).queryOrderedByValue().queryEqual(toValue: true).rx.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<[String]> in
            if snapshot.exists() {

                let broadcastIds = snapshot.children.allObjects.map { $0 as! DataSnapshot }.map { $0.key }
                return getBroadcastsObservables(broadcastsIds: broadcastIds)
            }

            return Observable.empty()
        }

    }

    private static func getBroadcastsObservables(broadcastsIds: [String]) -> Observable<[String]> {

        let observersList = broadcastsIds.map { fetchBroadcast(broadcastId: $0).asObservable() }

        let observables = Observable.from(observersList).merge().toArray().asObservable()

        return observables


    }
}
