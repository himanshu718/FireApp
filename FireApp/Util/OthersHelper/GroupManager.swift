//
//  GroupManager.swift
//  FireApp
//
//  Created by Devlomi on 9/28/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase
import RealmSwift
import FirebaseDatabase
import FirebaseMessaging

import RxFirebaseStorage
import FirebaseStorage
import Kingfisher

enum GroupError: Error {
    case noGroupsFound
    case invalidData
}
var newMessageHandler:NewMessageHandler!
var disposeBag1 = DisposeBag()
var listOfListeningGroupIds = [String]()

public protocol NotificationBadgeDelegate: AnyObject {
    func refreshBadge()
}


weak var notificationBadgeDelegate:NotificationBadgeDelegate?

class GroupManager {
    
    public static func onlyAdminsCanPost(groupId: String, bool: Bool) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            let ref = FireConstants.groupsRef.child(groupId).child("info").child("onlyAdminsCanPost").rx
            ref.setValue(bool).asObservable().subscribe(onNext: nil, onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                RealmHelper.getInstance(appRealm).setOnlyAdminsCanPostInGroup(groupId: groupId, bool: bool)
                completable(.completed)
            })
            return Disposables.create()
        })
    }
    
    static func fetchGroupsForCurrentUser(userId: String) -> Observable<[Group]> {
        return Observable.create { observer in
            FireConstants.groupsRef.observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    var userGroups: [Group] = []
                    var adminUids = [String]()
                    for groupSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                        if let groupID = groupSnapshot.key as? String{
                            if groupIsMember(userId, in: groupSnapshot){
                                print("get new group xs : \(groupID)")
                                if isNeededToAdd(in: groupSnapshot){
                                    fetchAndCreateGroup(groupId: groupID, subscribeToTopic: true)
                                        .subscribe(onNext: { groups in
                                        
                                        }, onError: { error in
                                            print("Error: \(error)")
                                        })
                                    
                                    let group = RealmHelper.getInstance(appRealm).getGroup(groupId: groupID)
                                    if shouldSetTheListener(in:group) {
                                        print("set listener xs : \(groupID)")
                                        messageListener(groupID: groupID)
                                    }
                                } 
                            }
                        }
                    }
                    observer.onNext(userGroups)
                } else {
                    observer.onError(GroupError.noGroupsFound)
                }
            }
            return Disposables.create()
        }
    }
    
    static func groupIsMember(_ userId: String, in groupSnapshot: DataSnapshot) -> Bool {
        if let users = groupSnapshot.childSnapshot(forPath: "users").value as? [String: Bool] {
            if users[userId] == false{
                return true
            }else{
                return users[userId] ?? false
            }
        }
        return false
    }
    
    static func isNeededToAdd(in groupSnapshot: DataSnapshot) -> Bool {
        return groupSnapshot.childSnapshot(forPath: "users").hasChild(FireManager.getUid())
//            if users[userId] == false{
//                return true
//            }else{
//                return users[userId] ?? false
//            }
//        }
//        return false
    }
    
    static func shouldSetTheListener(in group:Results<Group>) -> Bool {
        return group.first?.users.count ?? 0 > 1
    }
    
    public static func fetchAndCreateGroup(groupId: String, subscribeToTopic: Bool) -> Observable<User> {
        return FireConstants.groupsRef.child(groupId).rx.observeSingleEvent(.value).asObservable()
            .flatMap { snapshot -> Observable<([User], DataSnapshot)> in
                if snapshot.exists() {
                    let usersSnapshot = snapshot.childSnapshot(forPath: "users")
                    let usersUids = usersSnapshot.children.allObjects.map { $0 as! DataSnapshot }.map { $0.key }
                    return getUsersOfGroup(uids: usersUids).map { ($0, snapshot) }
                } else {
                    return Observable.empty()
                }
                
            }.map { (users: [User], snapshot: DataSnapshot) -> User in
                
                let info = snapshot.childSnapshot(forPath: "info")
                let usersSnapshot = snapshot.childSnapshot(forPath: "users")
                
                let groupName = info.childSnapshot(forPath: "name").value as? String ?? ""
                let photo = info.childSnapshot(forPath: "photo").value as? String ?? ""
                let thumbImg = info.childSnapshot(forPath: "thumbImg").value as? String ?? ""
                let createdBy = info.childSnapshot(forPath: "createdBy").value as? String ?? ""
                let createdAtTimestamp = info.childSnapshot(forPath: "timestamp").value as? Int ?? 0
                let onlyAdminsCanPost = info.childSnapshot(forPath: "onlyAdminsCanPost").value as? Bool ?? false
                
                var adminUids = [String]()
                for snapshot in usersSnapshot.children.allObjects {
                    if let snap = snapshot as? DataSnapshot, let isAdmin = snap.value as? Bool {
                        if isAdmin {
                            adminUids.append(snap.key)
                        }
                    }
                }
                
                return saveAndCreateNewGroup(groupId: groupId, groupTitle: groupName, thumbImg: thumbImg, photoUrl: photo, users: users, adminUids: adminUids, timestamp: createdAtTimestamp, createdBy: createdBy, onlyAdminsCanPost: onlyAdminsCanPost, isCreatedByThisUser: false)
            }.flatMap { groupUser -> Observable<(Void, User)> in
                if subscribeToTopic {
                    return Messaging.messaging().subscribeToTopicRx(topic: groupId).asObservable().map { ($0, groupUser) }
                } else {
                    return Observable.from(optional: (Void(), groupUser))
                }
            }.flatMap { _, groupUser -> Observable<(DataSnapshot, User)> in
                if subscribeToTopic {
                    RealmHelper.getInstance(appRealm).setGroupSubscribed(groupId: groupId, bool: true)
                }
                return FireConstants.groupsEventsRef.child(groupId).queryLimited(toLast: 10).rx.observeSingleEvent(.value).asObservable().map { ($0, groupUser) }
            }
            .map { snapshot, groupUser -> User in
                if snapshot.exists() {
                    for snap in snapshot.children.allObjects {
                        if let snap = snap as? DataSnapshot {
                            let groupEvent = snap.toGroupEvent()
                            //if it's a creation event
                            if groupEvent.contextStart == groupEvent.contextEnd {
                                groupEvent.type = .GROUP_CREATION
                                groupEvent.contextEnd = "null"
                            }
                            groupEvent.createGroupEvent(group: groupUser, eventId: groupEvent.eventId)
                        }
                    }
                }
                return groupUser
            }.do(onCompleted: {
                RealmHelper.getInstance(appRealm).deletePendingGroupJob(groupId: groupId)
            })
                }
    
    public static func joinViaGroupLink(groupLink: String) -> Observable<DatabaseReference> {
        return getGroupIdByGroupLink(groupLink: groupLink).flatMap { groupId in
            return fetchAndCreateGroup(groupId: groupId, subscribeToTopic: true).map { ($0, groupId) }
        }.flatMap { _, groupId in
            return FireConstants.groupsRef.child(groupId).child("users").child(FireManager.getUid()).rx.setValue(false)
        }
    }
    
    public static func getGroupIdByGroupLink(groupLink: String) -> Observable<String> {
        return FireConstants.groupsLinks.child(groupLink).rx.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<String> in
            if snapshot.exists(), let groupId = snapshot.value as? String {
                
                return Observable.from(optional: groupId)
            }
            return Observable.error(InvalidGroupLinkError())
        }
    }
    
    private static func saveAndCreateNewGroup(groupId: String, groupTitle: String, thumbImg: String, photoUrl: String, users: [User], adminUids: [String], timestamp: CLong, createdBy: String, onlyAdminsCanPost: Bool, isCreatedByThisUser: Bool) -> User {
        
        let groupUser = User()
        groupUser.userName = groupTitle
        groupUser.photo = photoUrl
        groupUser.thumbImg = thumbImg
        
        let list = List<User>()
        for user in users {
            list.append(user)
        }
        
        let group = Group()
        
        let adminUidsList = List<String>()
        adminUidsList.append(objectsIn: adminUids)
        group.adminUids = adminUidsList
        
        group.groupId = groupId
        group.isActive = true
        group.users = list
        group.timestamp = timestamp
        group.createdByNumber = createdBy
        group.onlyAdminsCanPost = onlyAdminsCanPost
        
        groupUser.group = group
        groupUser.isGroupBool = true
        groupUser.uid = groupId
        
        if RealmHelper.getInstance(appRealm).getUser(uid: groupId) == nil{
            RealmHelper.getInstance(appRealm).saveObjectToRealm(object: groupUser, update: false)
            RealmHelper.getInstance().saveEmptyChat(user: groupUser)
        }
        
        if isCreatedByThisUser {
            let groupEvent = GroupEvent()
            groupEvent.contextStart = UserDefaultsManager.getPhoneNumber()!
            groupEvent.type = .GROUP_CREATION
            
            groupEvent.createGroupEvent(group: groupUser, eventId: nil)
            
            for user in list {
                if user.uid != FireManager.getUid() {
                    let groupEvent = GroupEvent()
                    groupEvent.contextStart = UserDefaultsManager.getPhoneNumber()!
                    groupEvent.type = .USER_ADDED
                    groupEvent.contextEnd = user.phone
                    groupEvent.createGroupEvent(group: groupUser, eventId: nil)
                }
            }
        }
        
        messageListener(groupID: groupId)
        
        return groupUser
    }
    
    //message listener
    public static func messageListener(groupID : String){
            print("set listener\(groupID)")
            if listOfListeningGroupIds.contains(groupID) {return}
            listOfListeningGroupIds.append(groupID)
            FireConstants.groupsMessages.observe(.childChanged, with: { (snapshot) in
                checkAndAddMessageToDatabase(groupID: groupID, snapshot: snapshot)
            })
            FireConstants.groupsMessages.observe(.childAdded, with: { (snapshot) in
                 checkAndAddMessageToDatabase(groupID: groupID, snapshot: snapshot)
            })
            FireConstants.groupsMessages.observe(.childRemoved, with: { (snapshot) in
                checkAndAddMessageToDatabase(groupID: groupID, snapshot: snapshot)
            })
            FireConstants.groupsMessages.observe(.childMoved, with: { (snapshot) in
                checkAndAddMessageToDatabase(groupID: groupID, snapshot: snapshot)
            })
        }
    
    public static func checkAndAddMessageToDatabase(groupID : String, snapshot : DataSnapshot){
        let chatList = RealmHelper.getInstance().getMessagesInChat(chatId: groupID)
        let message = Message()
        
        if let chatData = snapshot.value as? [String: Any] {
            
            chatData.forEach { chats in
                let chatDict = chats.value as? NSDictionary
                if RealmHelper.getInstance().getMessage(messageId: chats.key) == nil{
                    
                    let fromID = chatDict?.value(forKey: "fromId") as! String
                    if snapshot.key == groupID {
                        let currentUser = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
                        
                        if fromID != currentUser?.uid{
                            
                            if !chatList.map({ $0.messageId }).contains(snapshot.key) {
                                message.fromId = fromID
                                
                                if let content = chatDict?["content"] as? String {
                                    message.content = content
                                }
                                
                                if let encryptionType = chatDict?["encryptionType"] {
                                    message.encryptionType = "\(encryptionType)"
                                }
                                
                                if let fromPhone = chatDict?["fromPhone"] as? String {
                                    message.fromPhone = fromPhone
                                }
                                
                                if let timestamp = chatDict?["timestamp"] {
                                    message.timestamp = timestamp as! CLong
                                }
                                
                                if let messageType = chatDict?["type"] as? Int {
                                    let type = MessageType(rawValue: messageType)
                                    let convertedType = type!.convertSentToReceived()
                                    message.typeEnum = convertedType
                                }
                                
                                message.messageId = chats.key
                                message.chatId = snapshot.key
                                
                                let downloadManager:DownloadManager! = DownloadManager(disposeBag: disposeBag1)
                                newMessageHandler = NewMessageHandler(downloadManager: downloadManager, messageDecryptor: MessageDecryptor(decryptionHelper: DecryptionHelper()))
                                
                                if RealmHelper.getInstance().getMessage(messageId: message.messageId) == nil{
                                    
                                    print("first message read ------- ")
                                    newMessageHandler.saveNewMessage(message: message, appRealm: appRealm, fromId: fromID, phone: message.fromPhone, disposeBag: disposeBag1) {
                                        notificationBadgeDelegate?.refreshBadge()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static func createNewGroup(groupTitle: String, users: [User]) -> Single<User> {
        let groupId = FireConstants.groupsRef.childByAutoId().key!
        let photoFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        
        return Single.create { (single) -> Disposable in
            FireConstants.mainRef.child("defaultGroupProfilePhoto").rx.observeSingleEvent(.value).asObservable()
                .map { snpashot in
                    return snpashot.value as? String
                }.filterNil()
                .flatMap { photoUrl in
                    return Storage.storage().reference(forURL: photoUrl).rx.write(toFile: photoFile).map { (photoUrl, $0) }
                }.map { data -> (String, String, Dictionary<String, Any>) in
                    var result = [String: Any]()
                    var groupInfo = [String: Any]()
                    
                    let photoUrl = data.0
                    let image = UIImage(contentsOfFile: photoFile.path)!.toProfileImage
                    
                    let thumbImg = image.toProfileThumbImage.circled().toBase64StringPng()
                    
                    groupInfo[DBConstants.TIMESTAMP] = ServerValue.timestamp()
                    groupInfo["createdBy"] = UserDefaultsManager.getPhoneNumber()!
                    groupInfo["onlyAdminsCanPost"] = false
                    let usersDict = User.toDict(userList: users, addCurrentUser: true)
                    
                    groupInfo["name"] = groupTitle
                    
                    groupInfo["photo"] = photoUrl
                    groupInfo["thumbImg"] = thumbImg
                    result["info"] = groupInfo
                    result["users"] = usersDict
                    let dict = result as Dictionary<String, Any>
                    
                    let tuple = (photoUrl, thumbImg, dict)
                    return tuple
                    
                }.flatMap { data -> Observable<(String, String)> in
                    let photoUrl = data.0
                    let thumbImg = data.1
                    let result = data.2
                    
                    return FireConstants.groupsRef.child(groupId).rx.setValue(result).asObservable().map { _ in (photoUrl, thumbImg) }
                }.flatMap { photoUrl, thumbImg -> Observable<User> in
                    let groupUser = saveAndCreateNewGroup(groupId: groupId, groupTitle: groupTitle, thumbImg: thumbImg, photoUrl: photoUrl, users: users, adminUids: [FireManager.getUid()], timestamp: CLong(Date().currentTimeMillis()), createdBy: UserDefaultsManager.getPhoneNumber()!, onlyAdminsCanPost: false, isCreatedByThisUser: true)
                    
                    return Observable.from(optional: groupUser)
                }.flatMap { user in
                    return Messaging.messaging().subscribeToTopicRx(topic: user.uid).map { user }
                    
                }.subscribe(onNext: { (user) in
                    RealmHelper.getInstance(appRealm).setGroupSubscribed(groupId: groupId, bool: true)
                    single(.success(user))
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
    }
    
    
    public static func createNewGroupForSpecificOrder(groupId: String, groupTitle: String, users: [User]) -> Single<User> {
        let photoFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        
        return Single.create { (single) -> Disposable in
            FireConstants.mainRef.child("defaultGroupProfilePhoto").rx.observeSingleEvent(.value).asObservable()
                .map { snpashot in
                    return snpashot.value as? String
                }.filterNil()
                .flatMap { photoUrl in
                    return Storage.storage().reference(forURL: photoUrl).rx.write(toFile: photoFile).map { (photoUrl, $0) }
                }.map { data -> (String, String, Dictionary<String, Any>) in
                    var result = [String: Any]()
                    var groupInfo = [String: Any]()
                    
                    let photoUrl = data.0
                    let image = UIImage(contentsOfFile: photoFile.path)!.toProfileImage
                    
                    let thumbImg = image.toProfileThumbImage.circled().toBase64StringPng()
                    
                    
                    groupInfo[DBConstants.TIMESTAMP] = ServerValue.timestamp()
                    groupInfo["createdBy"] = UserDefaultsManager.getPhoneNumber()!
                    groupInfo["onlyAdminsCanPost"] = false
                    let usersDict = User.toDict(userList: users, addCurrentUser: true)
                    
                    groupInfo["name"] = groupTitle
                    
                    groupInfo["photo"] = photoUrl
                    groupInfo["thumbImg"] = thumbImg
                    result["info"] = groupInfo
                    result["users"] = usersDict
                    let dict = result as Dictionary<String, Any>
                    
                    let tuple = (photoUrl, thumbImg, dict)
                    return tuple
                    
                }.flatMap { data -> Observable<(String, String)> in
                    let photoUrl = data.0
                    let thumbImg = data.1
                    let result = data.2
                    return FireConstants.groupsRef.child(groupId).rx.setValue(result).asObservable().map { _ in (photoUrl, thumbImg) }
                }.flatMap { photoUrl, thumbImg -> Observable<User> in
                    let groupUser = saveAndCreateNewGroup(groupId: groupId, groupTitle: groupTitle, thumbImg: thumbImg, photoUrl: photoUrl, users: users, adminUids: [FireManager.getUid()], timestamp: CLong(Date().currentTimeMillis()), createdBy: UserDefaultsManager.getPhoneNumber()!, onlyAdminsCanPost: false, isCreatedByThisUser: true)
                    return Observable.from(optional: groupUser)
                }.flatMap { user in
                    return Messaging.messaging().subscribeToTopicRx(topic: user.uid).map { user }
                    
                }.subscribe(onNext: { (user) in
                    RealmHelper.getInstance(appRealm).setGroupSubscribed(groupId: groupId, bool: true)
                    single(.success(user))
                    print("success\(users)")
                }, onError: { (error) in
                    single(.error(error))
                })
            return Disposables.create()
        }
        
    }
    
    
    public static func removeGroupMember(groupId: String, userToRemove uid: String) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            FireConstants.groupsRef.child(groupId).child("users").child(uid).rx.removeValue().asObservable()
                .subscribe(onNext: nil, onError: { (error) in
                    completable(.error(error))
                }, onCompleted: {
                    
                    RealmHelper.getInstance(appRealm).deleteGroupMember(groupId: groupId, userToRemove: uid)
                    completable(.completed)
                })
            
            return Disposables.create()
        })
    }
    
    public static func makeGroupAdmin(groupUser: User, userToSet: User, setAdmin: Bool) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            let groupId = groupUser.uid
            
            FireConstants.groupsRef.child(groupId).child("users").child(userToSet.uid).rx.setValue(setAdmin).asObservable().subscribe(onNext: nil, onError: { (error) in
                
                completable(.error(error))
            }, onCompleted: {
                RealmHelper.getInstance(appRealm).setGroupAdmin(groupId: groupId, userToSet: userToSet.uid, setAdmin: setAdmin)
                let groupEventType:GroupEventType = setAdmin ? .ADMIN_ADDED : .ADMIN_REMOVED
                GroupEvent(contextStart: UserDefaultsManager.getPhoneNumber()!, type: groupEventType, contextEnd: userToSet.phone).createGroupEvent(group: groupUser, eventId: nil)
                completable(.completed)
            })
            return Disposables.create()
        })
        
    }
    
    public static func addParticipants(groupUser: User, users: [User]) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            let dict = User.toDict(userList: users, addCurrentUser: false)
            FireConstants.groupsRef.child(groupUser.uid).child("users").rx.updateChildValues(dict).asObservable().subscribe(onNext: nil, onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                RealmHelper.getInstance(appRealm).addUsersToGroup(groupId: groupUser.uid, usersToAdd: users)
                for user in users {
                    GroupEvent(contextStart: UserDefaultsManager.getPhoneNumber()!, type: .USER_ADDED, contextEnd: user.phone).createGroupEvent(group: groupUser, eventId: nil)
                }
                completable(.completed)
            })
            return Disposables.create()
        })
    }
    
    public static func changeGroupName(groupId: String, groupTitle: String) -> Completable {
        return Completable.create(subscribe: { (completable) -> Disposable in
            FireConstants.groupsRef.child(groupId).child("info").child("name").rx.setValue(groupTitle).asObservable().subscribe(onNext: nil, onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                
                RealmHelper.getInstance(appRealm).changeGroupName(groupId: groupId, groupName: groupTitle)
                completable(.completed)
            })
            return Disposables.create()
        })
    }
    
    public static func changeGroupImage(user: User, image: UIImage) -> Completable {
        
        return Completable.create(subscribe: { (completable) -> Disposable in
            
            let compressedImage = image.toProfileImage
            
            let file = DirManager.generateUserProfileImage()
            
            try? compressedImage.toDataPng()?.write(to: file)
            
            let ext = file.pathExtension
            let fileName = UUID().uuidString + ext
            let ref = FireConstants.imageProfileRef.child(fileName).rx
            ref.putFile(from: file)
                .flatMap { _ in
                    return ref.downloadURL()
                }.flatMap { imageUrl -> Observable<DatabaseReference> in
                    var dict = [String: Any]()
                    let thumbImage = compressedImage.toProfileThumbImage.circled().toBase64StringPng()
                    dict["photo"] = imageUrl.absoluteString
                    dict["thumbImg"] = thumbImage
                    
                    return FireConstants.groupsRef.child(user.uid).child("info").rx.updateChildValues(dict).asObservable().map { (dict, $0) }
                        .map { data in
                            
                            let photoUrl = data.0["photo"] as! String
                            let thumb = data.0["thumbImg"] as! String
                            
                            RealmHelper.getInstance(appRealm).updateUserImg(uid: user.uid, imgUrl: photoUrl, localPath: file.path, oldLocalPath: user.userLocalPhoto)
                            
                            RealmHelper.getInstance(appRealm).updateThumbImg(uid: user.uid, thumbImg: thumb)
                            
                            
                            return data.1
                            
                        }
                }.subscribe(onNext: nil, onError: { (error) in
                    completable(.error(error))
                }, onCompleted: {
                    GroupEvent(contextStart: UserDefaultsManager.getPhoneNumber()!, type: .GROUP_SETTINGS_CHANGED, contextEnd: "null").createGroupEvent(group: user, eventId: nil)
                    completable(.completed)
                })
            return Disposables.create()
        })
    }
    
    private static func getSixUsersOfGroup(snapshot: DataSnapshot) -> Observable<[User]> {
        
        var observersList = [Observable<User>]()
        
        
        var i = 0
        
        for userSnapshot in snapshot.children.allObjects {
            let userSnap = userSnapshot as! DataSnapshot
            //get only six users
            if i == 6 {
                break
            }
            let uid = userSnap.key
            if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid) {
                observersList.append(Observable.from(optional: user))
            } else {
                observersList.append(FireManager.fetchUserByUid(uid: uid, appRealm: appRealm))
            }
            i += 1
        }
        
        let observables = Observable.from(observersList).merge().toArray().asObservable()
        
        return observables
    }
    
    private static func getUsersOfGroup(uids: [String]) -> Observable<[User]> {
        
        var observersList = [Observable<User>]()
        
        for uid in uids {
            if uid != FireManager.getUid() {
                if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid) {
                    observersList.append(Observable.from(optional: user))
                } else {
                    observersList.append(FireManager.fetchUserByUid(uid: uid, appRealm: appRealm))
                }
            }
        }
        
        let observables = Observable.from(observersList).merge().toArray().asObservable()
        return observables
    }
    
    public static func updateGroup(groupId: String, groupEvent: GroupEvent? = nil) -> Observable<Void> {
        return FireConstants.groupsRef.child(groupId).rx.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<Void> in
            let infoSnapshot = snapshot.childSnapshot(forPath: "info")
            let usersSnapshot = snapshot.childSnapshot(forPath: "users")
            
            
            let mUnfetchedUsers = RealmHelper.getInstance(appRealm).updateGroup(groupId: groupId, info: infoSnapshot, usersSnapshot: usersSnapshot)
            
            guard let unfetchedUsers = mUnfetchedUsers else {
                return Observable.from(optional: Void())
            }
            
            if let groupEvent = groupEvent {
                var mGroupEvent: GroupEvent!
                
                //if it is a creation event show whom created this group event
                if groupEvent.contextStart == groupEvent.contextEnd {
                    
                    mGroupEvent = GroupEvent(contextStart: groupEvent.contextStart, type: .GROUP_CREATION, contextEnd: "null")
                } else {
                    mGroupEvent = GroupEvent(contextStart: groupEvent.contextStart, type: groupEvent.type, contextEnd: groupEvent.contextEnd)
                }
                let group = RealmHelper.getInstance(appRealm).getUser(uid: groupId)
                if let group = group {
                    mGroupEvent.createGroupEvent(group: group, eventId: mGroupEvent.eventId)
                    
                    if unfetchedUsers.isNotEmpty {
                        return getUsersOfGroup(uids: unfetchedUsers).map { user in
                            RealmHelper.getInstance(appRealm).addUsersToGroup(groupId: groupId, usersToAdd: user)
                        }
                    } else {
                        //                        RealmHelper.getInstance(appRealm).deletePendingGroupCreationJob(groupId);
                        
                    }
                    
                } else {
                    if unfetchedUsers.isNotEmpty {
                        return getUsersOfGroup(uids: unfetchedUsers).map { user in
                            RealmHelper.getInstance(appRealm).addUsersToGroup(groupId: groupId, usersToAdd: user)
                        }
                    }
                }
            }
            return Observable.from(optional: Void()).do(onCompleted: {
                RealmHelper.getInstance(appRealm).deletePendingGroupJob(groupId: groupId)
            })
                }
    }
    
    public static func fetchUserGroups() -> Observable<[User]> {
        return FireConstants.groupsByUser.child(FireManager.getUid()).rx.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<[User]> in
            if snapshot.exists() {
                let groupsIds = snapshot.children.allObjects.map { $0 as! DataSnapshot }.map { $0.key }
                let observablesList = groupsIds.map { fetchAndCreateGroup(groupId: $0, subscribeToTopic: true) }
                let observables = Observable.from(observablesList).merge().toArray().asObservable()
                return observables
            }
            return Observable.empty()
        }
    }
    
    public static func exitGroup(groupId: String) -> Observable<DatabaseReference> {
        Messaging.messaging().unsubscribeFromTopicRx(topic: groupId).asObservable().flatMap { _ in
            return FireConstants.groupsRef.child(groupId).child("users").child(FireManager.getUid()).rx.removeValue()
        }.do(onCompleted: {
            RealmHelper.getInstance(appRealm).exitGroup(groupId: groupId)
            let groupEvent = GroupEvent(contextStart: UserDefaultsManager.getPhoneNumber()!, type: .USER_LEFT_GROUP, contextEnd: "null")
            if let user = RealmHelper.getInstance(appRealm).getUser(uid: groupId) {
                groupEvent.createGroupEvent(group: user, eventId: nil)
            }
        })
            }
    
    public static func isAdmin(adminUids: List<String>) -> Bool {
        return adminUids.contains(FireManager.getUid())
    }
    
    public static func subscribeToUnsubscribedGroups() -> Observable<Void> {
        let unsubscribedGroups = RealmHelper.getInstance(appRealm).getUnsubscribedGroups()
        let messaging = Messaging.messaging()
        var observables = [Observable<Void>]()
        for group in unsubscribedGroups {
            let observable =
            messaging.subscribeToTopicRx(topic: group.groupId).asObservable().do(onCompleted: {
                RealmHelper.getInstance(appRealm).setGroupSubscribed(groupId: group.groupId, bool: true)
            })
                
                observables.append(observable)
                }
        
        return Observable.merge(observables)
        
    }
    
    public static func subscribeToGroupTopic(groupId: String) -> Observable<Void> {
        
        let messaging = Messaging.messaging()
        
        return messaging.subscribeToTopicRx(topic: groupId).asObservable().do(onCompleted: {
            RealmHelper.getInstance(appRealm).setGroupSubscribed(groupId: groupId, bool: true)
        })
    }
}

