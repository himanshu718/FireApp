//
//  NewMessageHandler.swift
//  FireApp
//
//  Created by Devlomi on 2/9/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import RealmSwift
//import MapKit
import Foundation
import RxSwift
import UIKit

protocol newChatCountDelegate: AnyObject {
    func newSetupBadge()
}

struct NewMessageHandler {
    
    let downloadManager:DownloadManager
    let messageDecryptor:MessageDecryptor
    
    static var customChatId:String = ""


    public func saveNewMessage(message: Message, appRealm: Realm, fromId: String, phone: String, disposeBag: DisposeBag,complete: (@escaping () -> Void)) {

        let realmHelper = RealmHelper.getInstance(appRealm)
        
        let needsToFetchUserData = realmHelper.getUser(uid: message.chatId) == nil
             //if unknown number contacted us ,we want to download his data and save it in local db
                if !message.isGroup && needsToFetchUserData{
                    FireManager.fetchUserDataAndSaveIt(phone: phone, disposeBag: disposeBag, appRealm: appRealm)
                }
        
        if realmHelper.getMessage(messageId: message.messageId, chatId: message.chatId) == nil
//            && realmHelper.getTempMessage(messageId: message.messageId) == nil
        {
            
            let tempMessage = TempMessage.mapMessageToTempMessage(message: message)
            realmHelper.saveObjectToRealm(object: tempMessage,update: false)
   
            Single.zip(fetchThumbIfNeeded(message: message),fetchContentIfNeeded(message: message)).flatMap{fetchThumbResult,fetchContentResult -> Single<Message> in
                if let thumb = fetchThumbResult{
                    message.thumb = thumb
                }
                
                if let content = fetchContentResult{
                    message.content = content
                    print(content)
                }
                return messageDecryptor.decryptMessage(message: message.detached())
            }.observeOn(MainScheduler.instance).subscribeOn(MainScheduler.instance).flatMap{decryptedMessage ->Single<Message> in
                print("decryptedMessage-=------ ",decryptedMessage)
                if decryptedMessage.typeEnum == MessageType.RECEIVED_LOCATION, let location = decryptedMessage.location {
                    return GetMapViewThumb.getMapView(location: location).map{uiImage in
                        if let image = uiImage{
                            let thumb = image.wxCompress().toBase64String()
                            decryptedMessage.thumb = thumb
                        }
                        return decryptedMessage
                    }
                }else{
                    return Single.just(decryptedMessage)
                }
            }.observeOn(MainScheduler.instance).subscribe { (decryptedMessage) in
            
                let status = decryptedMessage.quotedMessage?.status
                if status != nil{
                    decryptedMessage.quotedMessage?.status = nil
                }
            
                if  NewMessageHandler.customChatId == decryptedMessage.chatId {
                    decryptedMessage.isSeen = true
                }
            
                if RealmHelper.getInstance().getMessage(messageId: decryptedMessage.messageId) == nil {
                    MessageCreator.saveNewMessage(decryptedMessage, user: getUser(uid: fromId, phone: phone, appRealm: appRealm), appRealm: appRealm)
//                    notificationBadgeDelegate?.refreshBadge()
                    if decryptedMessage.isSeen == false{
                        RealmHelper.getInstance().saveUnreadMessage(messageId: decryptedMessage.messageId, chatId: decryptedMessage.chatId)
                    }
                }
                
                if status != nil, let storedStatus = realmHelper.getStatus(statusId: status!.statusId){
                    realmHelper.getMessageAndUpdateIt(messageId: decryptedMessage.messageId) { (message) in
                        message?.quotedMessage?.status = storedStatus
                    }
                }
                
                let messageType = decryptedMessage.typeEnum
                
                if AutoDownloadPossibility.canAutoDownload(type: messageType) && UserDefaultsManager.isAppInBackground() && (messageType == .RECEIVED_VOICE_MESSAGE || messageType == .RECEIVED_IMAGE || messageType == .RECEIVED_STICKER) {
                    
                    downloadManager.download(message: decryptedMessage, callback: nil, appRealm: appRealm)

                }
                
                realmHelper.deleteTempMessage(messageId: message.messageId)
            
                
                complete()
            } onError: { (error) in
            }.disposed(by: disposeBag)
            
        }
        
        
    }
    
    private func fetchThumbIfNeeded(message:Message) -> Single<String?>{
        guard message.typeEnum == .RECEIVED_IMAGE || message.typeEnum == .RECEIVED_VIDEO && message.thumb.isNotEmpty else {
            return Single.just(nil)
        }
        
        return FireConstants.userMessages.child(FireManager.getUid()).child(message.messageId)
            .child(DBConstants.THUMB).rx.observeSingleEvent(.value).map{snapshot in
                return snapshot.value as? String
            }
    }
    
    private func fetchContentIfNeeded(message:Message) -> Single<String?>{
        guard message.typeEnum == .RECEIVED_TEXT  && message.content.isNotEmpty else {
            return Single.just(nil)
        }
        
        return FireConstants.userMessages.child(FireManager.getUid()).child(message.messageId)
            .child(DBConstants.CONTENT).rx.observeSingleEvent(.value).map{snapshot in
                return snapshot.value as? String
            }
    }
    
    func handleNewMessage(userInfo: [AnyHashable: Any], disposeBag: DisposeBag, isSeen:Bool, complete: (@escaping () -> Void)) {
        
        guard FireManager.isLoggedIn else {
            return
        }
        
        
        let dict = userInfo
        let messageId = dict[DBConstants.MESSAGE_ID] as? String ?? ""
        let isGroup = dict.keys.contains("isGroup")
        //getting data from fcm message and convert it to a message
        let phone = dict[DBConstants.PHONE] as? String ?? ""
        let content = dict[DBConstants.CONTENT] as? String ?? ""
        let timestampStr = dict[DBConstants.TIMESTAMP]as? String ?? Date().currentTimeMillisStr()
        let timestamp = Int(timestampStr) ?? Date().currentTimeMillisLong()
        let typeStr = dict[DBConstants.TYPE] as? String ?? "0"
        let typeInt = Int(typeStr) ?? 0
        
        let type = MessageType(rawValue: typeInt)
        //get sender uid
        let fromId = dict[DBConstants.FROM_ID]as? String ?? ""
        let toId = dict[DBConstants.TOID] as? String ?? ""
        let metadata = dict[DBConstants.METADATA] as? String ?? ""
        
        let mediaDuration = dict[DBConstants.MEDIADURATION] as? String ?? ""
        let fileSize = dict[DBConstants.FILESIZE] as? String ?? ""
        
        //convert sent type to received
        let convertedType = type!.convertSentToReceived()
        
        let thumb = dict["thumb"] as? String ?? ""
        
        let encryptionType = dict[DBConstants.ENCRYPTION_TYPE] as? String ?? EncryptionType.NONE
        
        //if it's a group message and the message sender is the same
        if fromId == FireManager.getUid() {
            return
        }
        
        //if message is deleted do not save it
        if RealmHelper.getInstance(appRealm).getDeletedMessage(messageId: messageId) != nil {
            return
        }
        
        let message = Message()
        
        message.encryptionType = encryptionType
        
        
        if let quotedMessageId = dict["quotedMessageId"] as? String, let quotedMessage = RealmHelper.getInstance(appRealm).getMessage(messageId: quotedMessageId) {
            message.quotedMessage = QuotedMessage.messageToQuotedMessage(quotedMessage)
        }
        
        //status reply
        if let statusId = dict["statusId"] as? String, let status = RealmHelper.getInstance(appRealm).getStatus(statusId: statusId){
            message.status = status
            let quotedMessage = StatusHelper.statusToMessage(status: status, userId: fromId)
            quotedMessage.fromId = FireManager.getUid()
            quotedMessage.chatId = fromId
            message.quotedMessage = QuotedMessage.messageToQuotedMessage(quotedMessage)
        }
        
        
        
        if let contactJsonString = userInfo["contact"] as? String {
            message.downloadUploadState = .DEFAULT
            let realmContact = RealmContact(name: content, numbers: List<PhoneNumber>())
            realmContact.jsonString = contactJsonString
            message.contact = realmContact
        }
        
        if userInfo["location"] != nil {
            
            message.downloadUploadState = .DEFAULT
            if let lat = userInfo["lat"] as? String, let lng = userInfo["lng"] as? String{
                let name = userInfo["name"] as? String ?? ""
                let address = userInfo["address"] as? String ?? ""
                let location = RealmLocation( lat: lat, lng: lng,address: address, name: name)
                message.location = location
            }
        }
        
        
        
        //create the message
        
        message.content = content
        message.timestamp = timestamp
        message.fromId = fromId
        message.typeEnum = convertedType
        message.messageId = messageId
        message.toId = toId
        message.chatId = isGroup ? toId : fromId
        message.isGroup = isGroup
        message.thumb = thumb
        message.metatdata = metadata
        message.mediaDuration = mediaDuration
        message.fileSize = fileSize
        
        
        
        if (isGroup) {
            message.fromPhone = phone
        }
        
        
        //set it to loading to start downloading automatically when the app starts
        let downloadUploadState:DownloadUploadState = AutoDownloadPossibility.canAutoDownload(type: message.typeEnum) ? .LOADING : .FAILED
        
        message.downloadUploadState = downloadUploadState
        
        saveNewMessage(message: message, appRealm: appRealm, fromId: fromId, phone: phone, disposeBag: disposeBag,complete: {
            complete()
            
        })
        
        
        
        
    }
    
    
    func getUser(uid: String, phone: String, appRealm: Realm) -> User {
        if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid) {
            return user
        }
        
        //save temp user data while fetching all data later
        let user = User()
        user.phone = phone
        user.uid = uid
        user.userName = phone
        user.isStoredInContacts = false
        
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user)
        
        
        return user
    }
}
