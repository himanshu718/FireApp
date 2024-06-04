//
//  DownloadManager.swift
//  FireApp
//
//  Created by Devlomi on 9/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import FirebaseStorage
import SwiftEventBus
import RealmSwift
import RxSwift


//this class is responsible for making upload/download files from Firebase Storage
//it's also responsible for saving messages in database
struct DownloadManager {

    let disposeBag:DisposeBag
    
    typealias Callback = (_ isSuccess: Bool) -> Void

    //save the file download task to cancel it later if user wants to
    public static var downloadTaskDict = [String: StorageDownloadTask]()


    //used in activity to get the current progress
    private static var progressDataDict = [String: ProgressData]()

    private func updateJobCallback(isSuccess: Bool, callback: Callback?) {
        callback?(isSuccess)
    }

   
 

    public func download(message: Message, callback: Callback?,appRealm:Realm) {
        let type = message.typeEnum
        let link = message.content
        let messageId = message.messageId
        let receiverId = message.chatId



        let fileExt = URL(string: link)?.pathExtension ?? ""
        
        let file = DirManager.generateFile(type: type,fileExtension: fileExt)
        let storageRef = FireConstants.storageRef.child(link)
        
        
        RealmHelper.getInstance(appRealm).changeDownloadOrUploadStat(messageId: messageId, state: .LOADING)

        let task = storageRef.write(toFile: file) { (meta, storageError) in
            DownloadManager.onComplete(id: messageId)
            DownloadManager.removeProgressFromDict(messageId: messageId)
            DownloadManager.removeTaskFromHashmap(messageId: messageId)

            //if download completed successfully and the user did not cancel the process

            if storageError == nil && message.completeAfterDownload() {
                if type.isVideo() {
                    let videoThumb = VideoUtil.generateThumbnail(path: file)?.toBase64String() ?? ""
                    RealmHelper.getInstance(appRealm).setVideoThumb(messageId: messageId, chatId: message.chatId, videoThumb: videoThumb)
                }
                RealmHelper.getInstance(appRealm).updateDownloadUploadStat(messageId: messageId, downloadUploadStat: .SUCCESS, filePath: file.path)

                
                if UserDefaultsManager.saveToCameraRoll() && type.isImage() || type.isVideo()  {
                    let mediaToSave = MediaToSave(id: message.messageId, path: message.localPath, isVideo: type.isVideo())
                    RealmHelper.getInstance(appRealm).saveObjectToRealm(object: mediaToSave)
                }

           


                updateJobCallback(isSuccess: true, callback: callback)


            } else {
                if let error = storageError as NSError?, error.code != StorageErrorCode.cancelled.rawValue {

                    RealmHelper.getInstance(appRealm).changeDownloadOrUploadStat(messageId: messageId, state: .FAILED);
                    updateJobCallback(isSuccess: false, callback: callback);
                } else {
                    updateJobCallback(isSuccess: true, callback: callback);
                }

                DownloadManager.onComplete(id: messageId)
                try? file.deleteFile()
                
            }

        }
        task.observe(.progress) { (snapshot) in
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
            / Double(snapshot.progress!.totalUnitCount)


            DownloadManager.fillProgressDict(messageId: messageId, receiverId: receiverId, progress: Float(percentComplete))

            //update progress in UI
            DownloadManager.updateProgress(id: messageId, progress: Float(percentComplete))
        }

        DownloadManager.fillTaskDict(messageId: messageId, downloadTask: task)


    }

//save file link from firebase storage in realm to use it later when forward a message
    private static func setMessageContent(filePath: String, message: Message,appRealm:Realm) {

        RealmHelper.getInstance(appRealm).changeMessageContent(messageId: message.messageId, content: filePath);


    }

    private static func onComplete(id: String) {
        SwiftEventBus.post(EventNames.networkCompleteEvent, sender: DownloadCompleteEvent(id: id))
    }

    private static func fillTaskDict(messageId: String, downloadTask: StorageDownloadTask) {
        downloadTaskDict[messageId] = downloadTask
    }

   

    private static func fillProgressDict(messageId: String, receiverId: String, progress: Float) {
        let progressData = ProgressData(progress: progress, receiverId: receiverId, messageId: messageId)
        progressDataDict[messageId] = progressData
    }

    private static func removeTaskFromHashmap(messageId: String) {
        downloadTaskDict.removeValue(forKey: messageId)
    }

    private static func removeProgressFromDict(messageId: String) {
        downloadTaskDict.removeValue(forKey: messageId)
    }

    private static func updateProgress(id: String, progress: Float) {
        SwiftEventBus.post(EventNames.networkProgressEvent, sender: ProgressEventData(id: id, progress: progress))
    }


    public static func cancelDownload(message: Message,appRealm:Realm) {

        let messageId = message.messageId
        if let fileDownloadTask = downloadTaskDict[messageId] {
            fileDownloadTask.cancel()
            removeTaskFromHashmap(messageId: messageId)

            try? URL(fileURLWithPath: message.localPath).deleteFile()

        }

        removeProgressFromDict(messageId: messageId);
        RealmHelper.getInstance(appRealm).changeDownloadOrUploadStat(messageId: messageId, state: .CANCELLED)

    }





    public static func cancelDownload(messageId: String,appRealm:Realm) {
        guard let message = RealmHelper.getInstance(appRealm).getMessage(messageId: messageId) else {
            return
        }

        if let fileDownloadTask = downloadTaskDict[messageId] {
            fileDownloadTask.cancel()
            downloadTaskDict.removeValue(forKey: messageId)
            try! URL(fileURLWithPath: message.localPath).deleteFile()
        }


        removeProgressFromDict(messageId: messageId)
        RealmHelper.getInstance(appRealm).changeDownloadOrUploadStat(messageId: messageId, state: .CANCELLED)
        


    }


  
  


}
