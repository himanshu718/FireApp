//
// Created by Devlomi on 2019-07-15.
// Copyright (c) 2019 Devlomi. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import RxFirebase
import RxSwift
import FirebaseFunctions
import RealmSwift
import Contacts
import SwiftEventBus

class FireManager {
    
    static func generateKey() -> String {
        return Database.database().reference().child("messages").childByAutoId().key!
    }
    
    
    static func auth() -> Auth {
        let auth = Auth.auth()
        do {
            try auth.useUserAccessGroup(nil)
            
        } catch let error {
            
        }
        return auth
        
    }
    static func getUid() -> String {
        
            return auth().currentUser!.uid
    }
    
    static var isLoggedIn: Bool {
        return auth().currentUser != nil
    }
    
    static var number: String? {
        return auth().currentUser?.phoneNumber
    }
    
    static var email: String? {
        return auth().currentUser?.email
    }
    
    
    static func downloadUserPhoto(user: User, photoUrl: String, appRealm: Realm) -> Observable<String> {
        if user.photo == "" {
            
            return Observable.empty()
        }
        let ref = Storage.storage().reference(forURL: photoUrl).rx
        let filePath = DirManager.generateUserProfileImage()
        
        let observable = ref.write(toFile: filePath)
            .map { data -> String in
                RealmHelper.getInstance(appRealm).updateUserImg(uid: user.uid, imgUrl: photoUrl, localPath: filePath.path, oldLocalPath: user.userLocalPhoto)
                
                return filePath.path
                
            }
        return observable
    }
    
    static func downloadPhoto(photoUrl: String) -> Observable<String> {
        if photoUrl == "" {
            return Observable.empty()
        }
        
        let ref = Storage.storage().reference(forURL: photoUrl).rx
        let filePath = DirManager.generateUserProfileImage()
        return ref.write(toFile: filePath).map { _ in filePath.path }
    }
    
    //check only for thumb img
    public static func checkAndDownloadUserThumb(user: User, appRealm: Realm) -> Observable<String> {
        
        let databaseReference = user.isGroupBool
        ? FireConstants.groupsRef.child(user.uid).child("info")
        : FireConstants.usersRef.child(user.uid)
        
        return databaseReference.child("thumbImg").rx.observeSingleEvent(.value).asObservable()
            .map { snapshot in
                return snapshot.value as? String
            }.filterNil().map { thumbImg -> String in
                if (user.thumbImg == "") {
                    RealmHelper.getInstance(appRealm).updateThumbImg(uid: user.uid, thumbImg: thumbImg)
                } else if (user.thumbImg != "" && user.thumbImg != thumbImg) {
                    RealmHelper.getInstance(appRealm).updateThumbImg(uid: user.uid, thumbImg: thumbImg)
                }
                return thumbImg
            }
    }
    
    public static func listenForTypingState(uid: String) -> Observable<TypingState> {
        return FireConstants.typingStat.child(uid).child(FireManager.getUid()).rx.observeEvent(.value)
        
            .map { $0.value as? Int }
            .filterNil()
            .map { stateInt -> TypingState in
                return TypingState(rawValue: stateInt) ?? TypingState.NOT_TYPING
            }
    }
    
    public static func listenForPresence(uid: String) -> Observable<PresenceState> {
        return FireConstants.presenceRef.child(uid).rx.observeEvent(.value)
            .map { $0.value }
            .filterNil()
            .map { value -> PresenceState in
                //the value is 'Online'
                if (value is String) {
                    return PresenceState(isOnline: true, lastSeen: 0)
                } else {
                    //get last seen
                    return PresenceState(isOnline: false, lastSeen: value as? Double ?? 0)
                }
            }
        
        
    }
    
    public static func listenForSentMessagesState (receiverUid: String, messageId: String, appRealm: Realm) -> Observable<MessageState> {
        return FireConstants.messageStat.child(receiverUid).child(messageId).rx.observeEvent(.value)
            .map { $0.value as? Int }
            .filterNil()
        
            .map { value -> MessageState in
                //the value is 'Online'
                let messageState = MessageState(rawValue: value)!
                
                RealmHelper.getInstance(appRealm).updateMessageStateLocally(messageId: messageId, chatId: receiverUid, messageState: messageState)
                
                
                return messageState
            }
        
        
    }
    
    
    public static func listenForSentVoiceMessagesState (receiverUid: String, messageId: String, appRealm: Realm) -> Observable<Void> {
        
        return FireConstants.voiceMessageStat.child(FireManager.getUid()).child(messageId).rx.observeEvent(.value)
            .map { $0.value as? Bool }
            .filterNil()
        
            .map { value -> Void in
                RealmHelper.getInstance(appRealm).updateVoiceMessageStateLocally(messageId: messageId, chatId: receiverUid)
                return Void()
            }
        
        
    }
    
    
    
    public static func setUserBlocked(blockedUserUid: String, setBlocked: Bool, appRealm: Realm) -> Completable {
        let ref = FireConstants.blockedUsersRef.child(FireManager.getUid()).child(blockedUserUid).rx
        
        
        
        return Completable.create(subscribe: { (completable) -> Disposable in
            var observable: Observable<DatabaseReference>!
            if setBlocked {
                observable = ref.setValue(true).asObservable()
                
            } else {
                observable = ref.removeValue().asObservable()
            }
            
            observable.subscribe(onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                RealmHelper.getInstance(appRealm).setUserBlocked(uid: blockedUserUid, setBlocked: setBlocked)
                completable(.completed)
            }, onDisposed: nil)
            return Disposables.create()
        })
        
    }
    
    public static func fetchUserByUid(uid: String, appRealm: Realm) -> Observable<User> {
        
        let userObservable = FireConstants.usersRef.child(uid).rx.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<(CNContact?, User)> in
            
            if !snapshot.exists() {
                return Observable.empty()
            }
            
            let user = snapshot.toUser()
            user.uid = snapshot.ref.key ?? ""
            
            
            return ContactsUtil.searchForContactByPhoneNumber(phoneNumber: user.phone).map { ($0, user) }
            
        }.map { (arg) -> User in
            
            let (contact, user) = arg
            
            user.userName = contact?.givenName ?? user.phone
            user.isStoredInContacts = contact != nil
            DispatchQueue.main.async {
                RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user)
            }
            return user
        }
        
        return userObservable
    }
    
    //check if there is a new photo for this user and download it
    //check for both thumb and full photo
    public static func checkAndDownloadUserPhoto(user: User, appRealm: Realm) -> Single<(String, String)> {
        let ref = user.isGroupBool ? FireConstants.groupsRef.child(user.uid).child("info") : FireConstants.usersRef.child(user.uid)
        
        
        let observable = ref.rx.observeSingleEvent(.value).asObservable().filter { $0.exists() }.flatMap { snapshot -> Observable<(String, String)> in
            
            let photo = snapshot.childSnapshot(forPath: "photo").value as! String
            let thumbImg = snapshot.childSnapshot(forPath: "thumbImg").value as! String
            
            
            
            if user.thumbImg != thumbImg {
                RealmHelper.getInstance(appRealm).updateThumbImg(uid: user.uid, thumbImg: thumbImg)
            }
            
            if photo != user.photo || user.userLocalPhoto == "" {
                return FireManager.downloadUserPhoto(user: user, photoUrl: photo, appRealm: appRealm).flatMap { photoPath in
                    return Observable.from(optional: (thumbImg, photoPath))
                }
            }
            
            return Observable.from(optional: (thumbImg, user.userLocalPhoto))
        }
        
        return Single.create(subscribe: { (observer) -> Disposable in
            observable.subscribe(onNext: { (thumb, photoPath) in
                observer(.success((thumb, photoPath)))
            }, onError: { (error) in
                observer(.error(error))
            }, onCompleted: nil, onDisposed: nil)
        })
    }
    
    //set the current presence as Online
    public static func setOnlineStatus() -> Observable<DatabaseReference> {
        return FireConstants.presenceRef.child(getUid()).rx.setValue("Online").asObservable().do(onCompleted: {
            UserDefaultsManager.setCurrentPresenceState(state: .online)
        })
            
            }
    
    //set last seen value,this will set value at the Server Time
    //so if the device clock is not correct it will not affect the last seen value
    public static func setLastSeen() -> Observable<DatabaseReference> {
        return FireConstants.presenceRef.child(getUid()).rx.setValue(ServerValue.timestamp()).asObservable().do(onCompleted: {
            UserDefaultsManager.setCurrentPresenceState(state: .lastSeen)
        })
            }
    
    //set the typing or recording or do nothing state
    public static func setTypingStat(receiverUid: String, stat: TypingState, isGroup: Bool, isBroadcast: Bool) -> Observable<Void> {
        if (isBroadcast) { return Observable.from(optional: Void()) }
        
        var ref: DatabaseReference!
        
        if (isGroup) {
            ref = FireConstants.groupTypingStat.child(receiverUid).child(FireManager.getUid())
        } else {
            ref = FireConstants.typingStat.child(FireManager.getUid()).child(receiverUid)
        }
        
        return ref.rx.setValue(stat.rawValue).asObservable().debounce(RxTimeInterval.milliseconds(200), scheduler: MainScheduler.instance).distinctUntilChanged().map { _ in Void() }
    }
    
    public static func isUserBlocked(otherUserUid: String) -> Single<Bool> {
        let observable = FireConstants.blockedUsersRef.child(otherUserUid).child(FireManager.getUid()).rx.observeSingleEvent(.value).asObservable().map { snapshot -> Bool in
            if let value = snapshot.value as? Bool {
                return value
            }
            return false
        }
        
        return Single.create { (single) -> Disposable in
            observable.subscribe(onNext: { (isBlocked) in
                single(.success(isBlocked))
            }, onError: { (error) in
                single(.error(error))
            })
            return Disposables.create()
        }
        
    }
    
    public static func isCallCancelled(userId: String, callId: String) -> Single<Bool> {
        let uid = FireManager.getUid()
        
        let observable = FireConstants.callsRef.child(uid).child(userId).child(callId).rx.observeSingleEvent(.value).asObservable().map { snapshot -> Bool in
            
            if let bool = snapshot.value as? Bool {
                return bool
            }
            return false
            
        }
        
        
        return Single.create { (single) -> Disposable in
            observable.subscribe(onNext: { (isCancelled) in
                single(.success(isCancelled))
            }, onError: { (error) in
                single(.error(error))
            })
            return Disposables.create()
        }
        
    }
    
    public static func setCallCancelled(userId: String, callId: String) -> Completable {
        Completable.create { (completable) -> Disposable in
            FireConstants.callsRef.child(FireManager.getUid()).child(userId).child(callId).rx.setValue(true).asObservable().subscribe(onError: { (error) in
                completable(.error(error))
                
            }, onCompleted: {
                completable(.completed)
            })
            return Disposables.create()
        }
        
    }
    
    
    public static func changeUserName(userName: String, appRealm: Realm) -> Completable {
        Completable.create { (completable) -> Disposable in
            FireConstants.usersRef.child(FireManager.getUid()).child("name").rx.setValue(userName).asObservable().subscribe(onError: { (error) in
                completable(.error(error))
                
            }, onCompleted: {
                RealmHelper.getInstance(appRealm).changeUserName(userName: userName)
                completable(.completed)
            })
            return Disposables.create()
        }
        
    }
    
    public static func changeMyStatus(status: String, appRealm: Realm) -> Completable {
        return Completable.create { (completable) -> Disposable in
            
            FireConstants.usersRef.child(FireManager.getUid()).child("status").rx.setValue(status).asObservable().subscribe(onError: { (error) in
                completable(.error(error))
            }, onCompleted: {
                RealmHelper.getInstance(appRealm).changeMyStatus(status: status)
                completable(.completed)
            })
            
            return Disposables.create()
        }
        
    }
    
    public static func changeMyPhotoObservable(image: UIImage, appRealm: Realm) -> Observable<(String, String, String)> {
        
        let localUrl = DirManager.generateUserProfileImage()
        let imageCompressed = image.toProfileImage
        
        try! imageCompressed.toDataPng()?.write(to: localUrl)
        
        let fileName = localUrl.lastPathComponent
        
        let thumbImg = image.toProfileThumbImage.circled().toBase64StringPng()
        
        let ref = FireConstants.imageProfileRef.child(fileName)
        
        return ref.rx.putFile(from: localUrl).flatMap { mRef -> Observable<URL> in
            return ref.rx.downloadURL()
        }.flatMap { url -> Observable<URL> in
            var updateDict = [String: String]()
            updateDict["photo"] = url.absoluteString
            updateDict["thumbImg"] = thumbImg
            
            return FireConstants.usersRef.child(FireManager.getUid()).rx.updateChildValues(updateDict).asObservable().flatMap { _ in
                return Observable.from(optional: url)
            }
            
        }.map { url -> (String, String, String) in
            let oldLocalPath = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())?.userLocalPhoto ?? ""
            
            RealmHelper.getInstance(appRealm).updateUserImg(uid: FireManager.getUid(), imgUrl: url.absoluteString, localPath: localUrl.path, oldLocalPath: oldLocalPath, thumbImg: thumbImg)
            
            return (thumbImg, localUrl.path, url.absoluteString)
        }
        
    }
    
    
    
    public static func changeMyPhoto(image: UIImage, appRealm: Realm) -> Completable {
        
        let localUrl = DirManager.generateUserProfileImage()
        
        let imageCompressed = image.toProfileImage
        
        try? imageCompressed.toDataPng()?.write(to: localUrl)
        
        
        let fileName = localUrl.lastPathComponent
        
        let thumbImg = imageCompressed.toProfileThumbImage.circled().toBase64StringPng()
        
        let ref = FireConstants.imageProfileRef.child(fileName)
        
        let observable = ref.rx.putFile(from: localUrl).flatMap { mRef -> Observable<URL> in
            return ref.rx.downloadURL()
        }.flatMap { url -> Observable<URL> in
            var updateDict = [String: String]()
            updateDict["photo"] = url.absoluteString
            updateDict["thumbImg"] = thumbImg
            
            
            
            
            return FireConstants.usersRef.child(FireManager.getUid()).rx.updateChildValues(updateDict).asObservable().flatMap { _ in
                return Observable.from(optional: url)
            }
            
        }.map { url -> String in
            
            let oldLocalPath = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())?.userLocalPhoto ?? ""
            
            RealmHelper.getInstance(appRealm).updateUserImg(uid: FireManager.getUid(), imgUrl: url.absoluteString, localPath: localUrl.path, oldLocalPath: oldLocalPath, thumbImg: thumbImg)
            
            return ""
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
    
    public static func setMessagesAsRead(chatId: String, appRealm: Realm) -> Observable<DatabaseReference> {
        let results = RealmHelper.getInstance(appRealm).getUnReadIncomingMessages(chatId: chatId)
        
        var observables = [Observable<DatabaseReference>]()
        
        
        for message in results {
            let state = MessageState.READ
            
            
            let observable = FireConstants.messageStat.child(FireManager.getUid()).child(message.messageId).rx.setValue(state.rawValue).asObservable().map { ref -> DatabaseReference in
                RealmHelper.getInstance(appRealm).updateMessageStateLocally(messageId: message.messageId, chatId: chatId, messageState: state)
                return ref
            }
            
            
            observables.append(observable)
        }
        
        return Observable.merge(observables)
        
    }
    
    //update message state as received or read
    public static func updateMessageState(messageId: String, chatId: String, state: MessageState, appRealm: Realm) -> Observable<DatabaseReference> {
        let unUpdatedState = UnUpdatedMessageState(messageId: messageId, myUid: FireManager.getUid(), chatId: chatId, statToBeUpdated: state)
        RealmHelper.getInstance(appRealm).saveObjectToRealmSafely(object: unUpdatedState, update: true)
        
        return FireConstants.messageStat.child(FireManager.getUid())
            .child(messageId).rx.setValue(state.rawValue).asObservable().do(onCompleted: {
                RealmHelper.getInstance(appRealm).updateMessageStateLocally(messageId: messageId, messageState: state)
                RealmHelper.getInstance(appRealm).deleteUnUpdatedState(messageId: messageId)
            })
                
                }
    
    //update voice message state to read
    public static func updateVoiceMessageStat(messageId: String, appRealm: Realm) -> Observable<DatabaseReference> {
        
        RealmHelper.getInstance(appRealm).getMessageAndUpdateIt(messageId: messageId) { (meesage) in
            
            if let message = meesage {
                message.voiceMessageNeedsToUpdateState = true
            }
        }
        
        return FireConstants.voiceMessageStat.child(FireManager.getUid())
            .child(messageId).rx.setValue(true).asObservable().do(onCompleted: {
                RealmHelper.getInstance(appRealm).getMessageAndUpdateIt(messageId: messageId) { (meesage) in
                    
                    if let message = meesage {
                        message.voiceMessageSeen = true
                        message.voiceMessageNeedsToUpdateState = false
                    }
                }
            })
                }
    
    public static func fetchUserDataAndSaveIt(phone: String, disposeBag: DisposeBag, appRealm: Realm) {
        FireManager.isHasFireApp(phone: phone, appRealm: appRealm).subscribe(onNext: { (user) in
            if let user = user {
                RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user, update: true)
            }
        }).disposed(by: disposeBag)
    }
    public static func isHasFireApp(phone: String, appRealm: Realm) -> Observable<User?> {
        if let user = RealmHelper.getInstance(appRealm).getUserByPhone(phone: phone) {
            return Observable.from(optional: user)
        }
        
        if isHasDeniedFirebaseStrings(string: phone) {
            return Observable.error(NSError())
        }
        
        let ref = FireConstants.uidByPhone.child(phone).rx
        return ref.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<DataSnapshot> in
            if snapshot.exists(), let uid = snapshot.value as? String {
                return FireConstants.usersRef.child(uid).rx.observeSingleEvent(.value).asObservable()
            } else {
                return Observable.error(NSError())
            }
        }.flatMap { snapshot -> Observable<(CNContact?, User)>in
            if !snapshot.exists() {
                return Observable.error(NSError())
                
            }
            let user = snapshot.toUser()
            return ContactsUtil.searchForContactByPhoneNumber(phoneNumber: phone).map { ($0, user) }
        }.map { tuple in
            let user = tuple.1
            user.userName = tuple.0?.givenName ?? user.phone
            user.isStoredInContacts = tuple.0 != nil
            return user
        }
    }
    
    private static let deniedFirebaseStrings = [".", "#", "$", "[", "]"]
    
    static func isHasDeniedFirebaseStrings(string: String) -> Bool {
        if string.trim().isEmpty {
            return true
        }
        
        for deniedString in deniedFirebaseStrings {
            if string.contains(deniedString) {
                return true
            }
        }
        return false
    }
    
    public static func getServerTime() -> Observable<Date> {
        return Functions.functions().httpsCallable("getTime").rx.call().map { result -> Date in
            let time = result.data as! Int
            let timeInterval = Double(time / 1000)
            let date = Date(timeIntervalSince1970: timeInterval)
            return date
        }
    }
    
    public static func saveDeviceId(uid:String) -> Completable{
        return FireConstants.deviceIdRef.child(uid).rx.setValue(DeviceId.id).asCompletable()
    }
    
    static func logout(){
        SwiftEventBus.post(EventNames.logout, sender: nil)
        do {
            try Auth.auth().signOut()
            
            UserDefaultsManager.setUserInfoSaved(false)
            UserDefaultsManager.setTokenSaved(bool: false)
            UserDefaultsManager.setUserDidLogin(false)
            UserDefaultsManager.setDeviceIdSaved(false)
            UserDefaultsManager.setE2ESaved(false)
        } catch let error as NSError {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    static func logoutAndDelete(){
        SwiftEventBus.post(EventNames.logout, sender:nil)
        try? auth().signOut()
        UserDefaultsManager.clearAll()
        RealmHelper.getInstance(appRealm).clearRealm()
    }
}
