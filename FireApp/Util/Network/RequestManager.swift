//
//  RequestManager.swift
//  FireApp
//
//  Created by Devlomi on 3/15/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase
import FirebaseStorage
import SwiftEventBus
import RealmSwift
import RxSwift

struct RequestManager {
    
    let disposeBag:DisposeBag
    let downloadManager:DownloadManager
    let uploadManager:UploadManager

    
       private static var jobIdDict = [String: Int]()
    
    typealias Callback = (_ isSuccess: Bool) -> Void

    public func request(message: Message, callback: Callback?, appRealm: Realm) {
        //prevent duplicate tasks
        if DownloadManager.downloadTaskDict[message.messageId] != nil || UploadManager.uploadTaskDict[message.messageId] != nil { return }

        let type = message.typeEnum


        if (type.isSentType()) {
            switch (type) {
            case .SENT_TEXT, .SENT_CONTACT, .SENT_LOCATION:

                uploadManager.sendMessage(message: message, callback: callback, appRealm: appRealm)

                break;
            default:
                if (message.isForwarded) {
                    uploadManager.sendMessage(message: message, callback: callback, appRealm: appRealm)
                } else {
                    uploadManager.upload(message: message, callback: callback, appRealm: appRealm)
                }
            }
        } else {
            RequestManager.beginBackgroundTask(messageId: message.messageId)
            downloadManager.download(message: message, callback: { (isSuccess) in
                if isSuccess{
                    if message.typeEnum.isVideo() || message.typeEnum.isImage(){
                        MediaSaver.saveMediaToSave()
                    }
                }
                
                callback?(isSuccess)
                RequestManager.endBackgroundTask(messageId: message.messageId)
            }, appRealm: appRealm )
            
        }

    }
    
    
    private static func endBackgroundTask(messageId: String) {
            if let taskId = jobIdDict[messageId] {
                UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: taskId))
            }

        }
    
        private static func beginBackgroundTask(messageId: String) -> UIBackgroundTaskIdentifier {
            let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            jobIdDict[messageId] = taskId.rawValue
            return taskId
        }
    
    
    
    public static func cancelDownload(message: Message,appRealm:Realm) {

        let messageId = message.messageId
  
        DownloadManager.cancelDownload(message: message, appRealm: appRealm)
        endBackgroundTask(messageId: messageId)
    }





    public static func cancelDownload(messageId: String,appRealm:Realm) {
        DownloadManager.cancelDownload(messageId: messageId, appRealm: appRealm)
        endBackgroundTask(messageId: messageId)
    }

}
