//
//  ScheduledMessagesManager.swift
//  FireApp
//
//  Created by Devlomi on 4/24/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import FirebaseDatabase
import FirebaseStorage
import SwiftEventBus

struct ScheduledMessagesManager {
    
    private let scheduledMessagesRef = FireConstants.mainRef.child("scheduledMessages")
    
    let disposeBag:DisposeBag
    let messageEncryptor = MessageEncryptor(encryptionHelper: EncryptionHelper())

    
     typealias Callback = (_ isSuccess: Bool) -> Void


      //save the file upload task to cancel it later if user wants to
      public static var uploadTaskDict = [String: StorageUploadTask]()

      //used in activity to get the current progress
      private static var progressDataDict = [String: ProgressData]()

      public static var jobIdDict = [String: Int]()
    
    public func updateJobCallback(isSuccess: Bool, callback: Callback?) {
        callback?(isSuccess)
    }
    

        public static func endBackgroundTask(messageId: String) {
            if let taskId = jobIdDict[messageId] {
                UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: taskId))
            }

        }
    
        public static func beginBackgroundTask(messageId: String) -> UIBackgroundTaskIdentifier {
            let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            jobIdDict[messageId] = taskId.rawValue
            return taskId
        }

     func uploadScheduledMessage(scheduledMessage: ScheduledMessage, callback: Callback?) {


        //get file path
        let filePath = scheduledMessage.localPath

        let pushKey = scheduledMessage.messageId
        //get file name from file path
        let fileName = filePath.fileName()

        let receivedId = scheduledMessage.chatId

        //get correct ref in firebase storage folders ,if it's an image it will be saved in images folder
        //if it's a video it will be saved in video folder
        let ref = FireConstants.getRef(type: scheduledMessage.typeEnum, fileName: fileName)

     
        let url = URL(fileURLWithPath: filePath)
        ScheduledMessagesManager.beginBackgroundTask(messageId: scheduledMessage.messageId)

        let copiedMessage = scheduledMessage.toMessage()
        messageEncryptor.encryptMessage(message: copiedMessage).observeOn(MainScheduler.instance).subscribe { (encryptedMessage) in
            let task = ref.putFile(from: url, metadata: nil) { (meta, storageError) in
                //UPDATE UI
                ScheduledMessagesManager.removeProgressFromDict(messageId: pushKey)
                ScheduledMessagesManager.removeTaskFromHashmap(messageId: pushKey)

                // check if upload is success && the user is not cancelled the upload request
                if storageError == nil && scheduledMessage.completeAfterDownload() {


                    let filePath = ref.fullPath
                    self.setMessageContent(filePath: filePath, message: scheduledMessage)
                    let ref = scheduledMessagesRef.child(FireManager.getUid())

                    
                    let copiedScheduledMessage = scheduledMessage.detached()
                    let encryptedScheduledMessage = ScheduledMessage.messageToScheduledMessage(message: encryptedMessage, scheduledMessage: copiedScheduledMessage)
                    
                    ref.child(scheduledMessage.messageId).updateChildValues(encryptedScheduledMessage.toMap(), withCompletionBlock: { (error, ref) in
                            //update download upload state if it's success or not

                        updateScheduledMessageStatus(messageId: scheduledMessage.messageId, state: .scheduled)
                            updateJobCallback(isSuccess: error == nil, callback: callback)

                            onComplete(id: pushKey)

                        })
                }


                else {
                    //if this process was not cancelled by the user (a network failure for example) then set the state as failed
                    if let error = storageError as NSError?, error.code != StorageErrorCode.cancelled.rawValue {
                        
                        updateJobCallback(isSuccess: false, callback: callback);
                    } else {
                        updateJobCallback(isSuccess: true, callback: callback);
                    }


                    onComplete(id: pushKey)
                }
            }

            task.observe(.progress) { (snapshot) in
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)


                ScheduledMessagesManager.fillProgressDict(messageId: pushKey, receiverId: receivedId, progress: Float(percentComplete))

                //update progress in UI
                updateProgress(id: pushKey, progress: Float(percentComplete))

            }



            ScheduledMessagesManager.fillTaskDict(messageId: scheduledMessage.messageId, uploadTask: task)


        } onError: { (erorr) in
            
        }.disposed(by: disposeBag)

       

    }

    //save file link from firebase storage in realm to use it later when forward a message


    func sendScheduledMessageMessage(scheduledMessage: ScheduledMessage, callback: Callback?) {
        scheduledMessagesRef.child(FireManager.getUid()).child(scheduledMessage.messageId).updateChildValues(scheduledMessage.toMap()) { (error, _) in
            if error == nil {
                updateScheduledMessageStatus(messageId: scheduledMessage.messageId, state: .scheduled)

            }
            updateJobCallback(isSuccess: error == nil, callback: callback)

        }
    }



    //save file link from firebase storage in realm to use it later when forward a message
    private func setMessageContent(filePath: String, message: ScheduledMessage) {

        if let foundMessage = getScheduledMessage(messageId: message.messageId) {

            try? appRealm.write {
                foundMessage.content = filePath
            }
        }
    }

    public func getScheduledMessage(messageId: String) -> ScheduledMessage? {
        return appRealm.objects(ScheduledMessage.self).filter("\(DBConstants.MESSAGE_ID) == '\(messageId)'").first
    }

    public func getScheduledMessages() -> Results<ScheduledMessage> {
        return appRealm.objects(ScheduledMessage.self).filter("state == \(ScheduledMessageState.scheduled.rawValue)")
    }

    public func deleteScheduledMessage(messageId: String) {
        if let scheduledMessage = getScheduledMessage(messageId: messageId) {
            scheduledMessagesRef.child(FireManager.getUid()).child(messageId).removeValue { (error, ref) in
                if error == nil {
                    try? appRealm.write {
                        appRealm.delete(scheduledMessage)
                    }
                }
            }
        }
    }

    public func updateScheduledMessageStatus(messageId: String, state: ScheduledMessageState) {
        if let message = getScheduledMessage(messageId: messageId) {
            try? appRealm.write {
                message.status = state
            }
        }
    }


    public func saveMessageAfterSchedulingSucceed(messageId: String, state: ScheduledMessageState) {
        if let scheduledMessage = getScheduledMessage(messageId: messageId) {
            try? appRealm.write {
                scheduledMessage.status = state
            }

            let isMessageExists = RealmHelper.getInstance(appRealm).getMessage(messageId: scheduledMessage.messageId) != nil

            if state == .executed && !isMessageExists {
                let message = scheduledMessage.toMessage()
                message.messageState = .SENT
                message.downloadUploadState = .SUCCESS
                if let user = RealmHelper.getInstance(appRealm).getUser(uid: scheduledMessage.toId) {
                    MessageCreator.saveNewMessage(message, user: user, appRealm: appRealm)
                }
            }
        }
    }

    public func listenForScheduledMessages() -> Observable<(String, ScheduledMessageState)> {

        let scheduledMessages = Observable.from(Array(getScheduledMessages()))

        return scheduledMessages.flatMap { message -> Observable<DataSnapshot> in
            return scheduledMessagesRef.child(FireManager.getUid()).child(message.messageId).rx.observeSingleEvent(.value).asObservable()
        }.flatMap { snapshot -> Observable<DataSnapshot> in
            if !snapshot.exists() {
                return Observable.empty()
            }

            return Observable.from(optional: snapshot)
        }.map { snap in
            

            let messageId = snap.childSnapshot(forPath: "messageId").value as? String ?? ""
            let stateInt = snap.childSnapshot(forPath: "state").value as? Int ?? 0
            let state: ScheduledMessageState = ScheduledMessageState(rawValue: stateInt) ?? ScheduledMessageState.unknown

            
            return (messageId, state)
        }

   
    }

    public func listenForScheduledMessages2() -> Observable<(String, ScheduledMessageState)> {


        return scheduledMessagesRef.child(FireManager.getUid()).rx.observeEvent(.childChanged).flatMap { snapshot -> Observable<DataSnapshot> in
            if !snapshot.exists() {
                return Observable.empty()
            }

            return Observable.from(optional: snapshot)
        }.map { snap in
            

            let messageId = snap.childSnapshot(forPath: "messageId").value as? String ?? ""
            let stateInt = snap.childSnapshot(forPath: "state").value as? Int ?? 0
            let state: ScheduledMessageState = ScheduledMessageState(rawValue: stateInt) ?? ScheduledMessageState.unknown

            return (messageId, state)
        }
    }

    
    public func onComplete(id: String) {
        UploadManager.endBackgroundTask(messageId: id)

        SwiftEventBus.post(EventNames.networkCompleteEvent, sender: DownloadCompleteEvent(id: id))
    }

 

    public static func fillTaskDict(messageId: String, uploadTask: StorageUploadTask) {
        uploadTaskDict[messageId] = uploadTask
    }

    public static func fillProgressDict(messageId: String, receiverId: String, progress: Float) {
        let progressData = ProgressData(progress: progress, receiverId: receiverId, messageId: messageId)
        progressDataDict[messageId] = progressData
    }

    public static func removeTaskFromHashmap(messageId: String) {
        uploadTaskDict.removeValue(forKey: messageId)
    }

    public static func removeProgressFromDict(messageId: String) {
        uploadTaskDict.removeValue(forKey: messageId)
    }

    public func updateProgress(id: String, progress: Float) {
        SwiftEventBus.post(EventNames.networkProgressEvent, sender: ProgressEventData(id: id, progress: progress))
    }



}

