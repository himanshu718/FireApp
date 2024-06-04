//
//  StatusManager.swift
//  FireApp
//
//  Created by Devlomi on 10/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase
import RealmSwift

class StatusManager {
    private static var statusesIds = [String]()
    private static var currentVideoDownloads = [String: Single<String>]()
    private static var lastSyncDate: Date?
    private static let waitTime = 15000 //15sec
    private static var fetchingLock = false

    public static func fetchStatuses(users: Results<User>) -> Completable {

        //prevent over-fetching
        //fetch only if 15secs has passed
        if fetchingLock {

            return Completable.create { (observer) -> Disposable in
                observer(.completed)
                return Disposables.create()
            }
        }
        if let lastSyncDate = lastSyncDate, !TimeHelper.shouldFetchStatuses(lastSyncTime: lastSyncDate) {

            return Completable.create { (observer) -> Disposable in
                observer(.completed)
                return Disposables.create()
            }
        }


        fetchingLock = true

        statusesIds.removeAll()
        return Completable.zip([
            fetchImageAndVideosStatuses(users: users),
            fetchTextStatuses(users: users)
            ]).do(onError: { (error) in
            fetchingLock = false
            lastSyncDate = Date()
        }, onCompleted: {
                fetchingLock = false
                lastSyncDate = Date()
                RealmHelper.getInstance(appRealm).deleteDeletedStatusesLocally(statusesIds: statusesIds)
            })
    }

    private static func fetchImageAndVideosStatuses(users: Results<User>) -> Completable {
        //add all statuses to this list to delete deleted statuses if needed
        //get current time before 24 hours (Yesterday)
        let timeBefore24Hours = TimeHelper.getTimeBefore24Hours()
        //get all user statuses that are not passed 24 hours



        let observable = Observable.from(users).flatMap { user -> Single<DataSnapshot> in

            let query = FireConstants.statusRef.child(user.uid)
                .queryOrdered(byChild: "timestamp").queryStarting(atValue: timeBefore24Hours)


            return query.rx.observeSingleEvent(.value)
        }.map { snapshot in
            handleStatus(dataSnapshot: snapshot)
        }

        return Completable.create { (completable) -> Disposable in
            observable.subscribe(onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                    completable(.completed)
                })
            return Disposables.create()

        }

    }

    private static func fetchTextStatuses(users: Results<User>) -> Completable {
        //add all statuses to this list to delete deleted statuses if needed
        //get current time before 24 hours (Yesterday)
        let timeBefore24Hours = TimeHelper.getTimeBefore24Hours()
        //get all user statuses that are not passed 24 hours


        let observable = Observable.from(users).flatMap { user -> Single<DataSnapshot> in
            let query = FireConstants.textStatusRef.child(user.uid)
                .queryOrdered(byChild: "timestamp").queryStarting(atValue: timeBefore24Hours)


            return query.rx.observeSingleEvent(.value)
        }.map { snapshot in
            handleStatus(dataSnapshot: snapshot)
        }

        return Completable.create { (completable) -> Disposable in
            observable.subscribe(onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                    completable(.completed)
                })
            return Disposables.create()

        }

    }
    private static func handleStatus(dataSnapshot: DataSnapshot) {


        for item in dataSnapshot.children.allObjects {
            if let snapshot = item as? DataSnapshot {
                let userId = snapshot.ref.parent!.key!
                let statusId = snapshot.key



                let status = snapshot.toStatus()

                statusesIds.append(statusId)
//                check if status is exists in local database, if not save it
                if (RealmHelper.getInstance(appRealm).getStatus(statusId: status.statusId) == nil) {
                    RealmHelper.getInstance(appRealm).saveStatus(userId: userId, status: status)

                }
            }

        }


    }

    public static func downloadVideoStatus(id: String, url: String, statusType: StatusType) -> Single<String> {
        //prevent duplicate events
        if let single = currentVideoDownloads[id] {
            return single
        }

        let file = DirManager.getReceivedStatusFile(statusId: id, statusType: statusType)

        let observable = FireConstants.storageRef.child(url).rx.write(toFile: file).map { _ -> String in
            RealmHelper.getInstance(appRealm).setLocalPathForVideoStatus(statusId: id, path: file.path)
            return file.path
        }

        let single = Single<String>.create { (single) -> Disposable in
            observable.subscribe(onNext: { (path) in
                single(.success(path))
                currentVideoDownloads.removeValue(forKey: id)
            }, onError: { (error) in
                    single(.error(error))
                    currentVideoDownloads.removeValue(forKey: id)
                }, onCompleted: nil)
            return Disposables.create()
        }

        currentVideoDownloads[id] = single

        return single




    }

    public static func uploadImageStatus(image: UIImage, thumbImg: UIImage) -> Completable {


        let status = StatusCreator.createImageStatus(image: image, thumb: thumbImg)


        let url = URL(fileURLWithPath: status.localPath)


        let fileName = url.lastPathComponent




        let ref = FireConstants.getRef(type: .STATUS_TYPE, fileName: fileName, isStatus: true)

        let observable = ref.rx.putFile(from: url).flatMap { _ in
            //if it's an image get a 'viewable' link
            //and if it's a video get a 'downloadable' link
//            if statusType == .image {
            return ref.rx.downloadURL()
//            }
//            return Observable.from("")
        }.flatMap { url -> Single<DatabaseReference> in
            try! appRealm.write {
                status.content = url.absoluteString
            }

            return Status.getMyStatusRef(type: .image).child(status.statusId).rx.updateChildValues(status.toDict())
        }.map { _ -> Status in
            RealmHelper.getInstance(appRealm).saveStatus(userId: FireManager.getUid(), status: status)
            return status
        }

        return Completable.create(subscribe: { (completable) -> Disposable in
            observable.subscribe(onNext: { (_) in
                completable(.completed)
            }, onError: { (error) in

                    completable(.error(error))
                })
            return Disposables.create()
        })
    }

    public static func uploadVideoStatus(videoUrl: URL) -> Completable {

        let status = StatusCreator.createVideoStatus(videoUrl: videoUrl)



        let fileName = videoUrl.lastPathComponent

        let ref = FireConstants.getRef(type: .STATUS_TYPE, fileName: fileName, isStatus: true)



        let observable = ref.rx.putFile(from: videoUrl).map { metadata -> String in

            //if it's an image get a 'viewable' link
            //and if it's a video get a 'downloadable' link


            return ref.fullPath

        }.flatMap { path -> Single<DatabaseReference> in
            try! appRealm.write {
                status.content = path
            }

            return Status.getMyStatusRef(type: .video).child(status.statusId).rx.updateChildValues(status.toDict())
        }.map { _ -> Status in
            RealmHelper.getInstance(appRealm).saveStatus(userId: FireManager.getUid(), status: status)
            return status
        }

        return Completable.create(subscribe: { (completable) -> Disposable in
            observable.subscribe(onNext: { (_) in
                completable(.completed)
            }, onError: { (error) in

                    completable(.error(error))
                })
            return Disposables.create()
        })
    }

    public static func uploadTextStatus(textStatus: TextStatus) -> Completable {

        let status = StatusCreator.createTextStatus(textStatus: textStatus)

        let observable = Status.getMyStatusRef(type: .text).child(status.statusId).rx.updateChildValues(status.toDict()).do(onSubscribe: {
            RealmHelper.getInstance(appRealm).saveStatus(userId: FireManager.getUid(), status: status)
        })


        return Completable.create(subscribe: { (completable) -> Disposable in

            observable.subscribe(onSuccess: { _ in
                completable(.completed)
            }, onError: { (error) in
                    completable(.error(error))
                })
            return Disposables.create()
        })
    }

    public static func deleteStatus(statusId: String, statusType: StatusType) -> Completable {

        let observable = Status.getMyStatusRef(type: statusType).child(statusId).rx.removeValue().do(onSuccess: { _ in
            RealmHelper.getInstance(appRealm).deleteStatus(userId: FireManager.getUid(), statusId: statusId)
        })

        return Completable.create(subscribe: { (completable) -> Disposable in
            observable.subscribe(onSuccess: { _ in
                completable(.completed)
            }, onError: { (error) in
                    completable(.error(error))
                })
            return Disposables.create()
        })
    }

    public static func setStatusSeen(uid: String, statusId: String) -> Single<DatabaseReference> {
        //save it locally in case if the use does not have internet connection
        var updateDict = [String: Any]()
        updateDict["uid"] = FireManager.getUid()
        updateDict["seenAt"] = ServerValue.timestamp()

        RealmHelper.getInstance(appRealm).saveUnProcessedJobSeen(uid: uid, statusId: statusId)
        return FireConstants.statusSeenUidsRef.child(uid).child(statusId).child(FireManager.getUid()).rx.setValue(updateDict).do(onSuccess: { _ in
            RealmHelper.getInstance(appRealm).setStatusSeenSent(statusId: statusId)
            RealmHelper.getInstance(appRealm).deleteUnProcessJobSeen(statusId: statusId)
        })
    }


    public static func getStatusSeenCount(statusId: String) -> Single<Int> {
        //save it locally in case if the use does not have internet connection


        return FireConstants.statusSeenUidsRef.child(FireManager.getUid()).child(statusId).rx.observeSingleEvent(.value).map { snapshot -> Int in
            if snapshot.exists() {
                return Int(snapshot.childrenCount)
            }

            return 0
        }.do(onSuccess: { (count) in
            RealmHelper.getInstance(appRealm).setStatusSeenCount(statusId: statusId, count: count)

        })
    }

    static func getStatusSeenByList(statusId: String) -> Single<(String,[StatusSeenBy])> {

        let reference = FireConstants.statusSeenUidsRef.child(FireManager.getUid()).child(statusId)


        return reference.rx.observeSingleEvent(.value).flatMap { (snapshot: DataSnapshot) -> Single<([User], DataSnapshot)> in
            if !snapshot.hasChildren() {
                return Single.error(NSError(domain: "No data", code: -1, userInfo: nil))
            }

            let userIds = snapshot.children.allObjects.map { ($0 as? DataSnapshot)?.key }.filter({ $0 != nil }).map { $0! }

            return UserByIdDataSource.getUsersByIds(uids: userIds).asSingle().map { ($0, snapshot) }

        }.map { tuple -> (String, [StatusSeenBy]) in
            let (users, dataSnapshot) = tuple

            var seenBy = [StatusSeenBy]()

            for child in dataSnapshot.children.allObjects {
                if let snap = child as? DataSnapshot {
                    let uid = snap.key
                    let seenAt = snap.childSnapshot(forPath: "seenAt").value as? Int ?? 0
                    if let foundUser = users.first(where: { $0.uid == uid }) {
                        seenBy.append(StatusSeenBy(user: foundUser, seenAt: seenAt))
                    }
                }
            }

            return (statusId, seenBy)

        }.do { (statusId,statusSeenBy) in
            RealmHelper.getInstance(appRealm).saveSeenByList(statusId: statusId, seenByList: statusSeenBy)
        }

    }

}
