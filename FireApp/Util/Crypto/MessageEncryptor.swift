//
//  MessageEncryptor.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift

struct MessageEncryptor {
    let encryptionHelper:EncryptionHelper
    
    
    func encryptMessage(message:Message) -> Single<Message> {
        var singles = [Single<Any>]()
        
        singles.append(encryptContent(message: message).flatMap{encryptedContent -> Single<(String?,String)> in
            if (message.typeEnum.isText() && encryptedContent.isNotEmpty  && encryptedContent.count > FireConstants.MAX_SIZE_STRING) {
                return encryptPartialText(message: message).map{($0,encryptedContent)}
            }else{
                return Single.just((nil,encryptedContent))
            }
            
        }.map{(partialText,encryptedContent) in
            if let partialText = partialText{
                message.partialText = partialText
            }
            
            message.content = encryptedContent
            return encryptedContent
        })

        singles.append(encryptThumb(message: message).map{
            message.thumb = $0
            return $0
        })
        
        singles.append(encryptContact(message: message).map{
            message.contact = $0
            return $0
        })
        
        singles.append(encryptLocation(message: message).map{
            message.location = $0
            return $0
        })

    

        return Single.zip(singles).map{_ in
            return message
        }
        
    }
    

    private func encryptContent(message:Message) -> Single<String>{
        if message.content.isEmpty{
            return Single.just(message.content)
        }
        
        let broadcastUids = message.broadcastUids.isEmpty ? nil : message.broadcastUids
        let toId = message.toId
        let uidToEncryptTo = SingleUidOrMultiple(uid: toId, uids: broadcastUids)
        return encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: message.content, encryptionType: message.encryptionType)
    }
    
    
    private func encryptPartialText(message:Message) -> Single<String>{
        if (message.content.isEmpty){
            return Single.just(message.content)
        }
        
        let broadcastUids = message.broadcastUids.isEmpty ? nil : message.broadcastUids
        let toId = message.toId
        let uidToEncryptTo = SingleUidOrMultiple(uid: toId, uids: broadcastUids)
        let split = String(message.content.dropLast(message.content.count / 2))
        return encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: split, encryptionType: message.encryptionType)
        
    }
    
    
    
    private func encryptContact(message:Message) -> Single<RealmContact?>{
        guard let contact = message.contact else {
            return Single.just(message.contact)
        }
    
        let broadcastUids = message.broadcastUids.isEmpty ? nil : message.broadcastUids
        let toId = message.toId
        let uidToEncryptTo = SingleUidOrMultiple(uid: toId, uids: broadcastUids)
        
        
        var encryptContactNameSingle:Single<String>?
        
        if contact.name.isNotEmpty {
            
             encryptContactNameSingle = encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: contact.name, encryptionType: message.encryptionType)
            
        }
        
        let numbersCombined = ContactMapper.mapNumbersToString(numbers: contact.realmList)
        
        let encryptNumbersSingle = encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: numbersCombined, encryptionType: message.encryptionType)
        
        if let encryptNameSingle = encryptContactNameSingle{
            return Single.zip(encryptNameSingle, encryptNumbersSingle).map { (encryptedName,encryptedNumbersJson) -> RealmContact in
                contact.name = encryptedName
                contact.jsonString = encryptedNumbersJson
                return contact
            }
        }
        
        return encryptNumbersSingle.map{
            contact.jsonString = $0
            return contact
        }
    }
    
    private func encryptThumb(message:Message) -> Single<String>{
        if message.thumb.isEmpty{
            return Single.just(message.thumb)
        }
        
        let broadcastUids = message.broadcastUids.isEmpty ? nil : message.broadcastUids
        let toId = message.toId
        let uidToEncryptTo = SingleUidOrMultiple(uid: toId, uids: broadcastUids)
        return encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: message.thumb, encryptionType: message.encryptionType)
    }

    
    private func encryptLocation(message:Message) -> Single<RealmLocation?>{
        guard let location = message.location else {
            return Single.just(message.location)
        }
    
        let broadcastUids = message.broadcastUids.isEmpty ? nil : message.broadcastUids
        let toId = message.toId
        let uidToEncryptTo = SingleUidOrMultiple(uid: toId, uids: broadcastUids)
        
        
        var singles = [Single<String>]()

        if location.name.isNotEmpty {
            
            singles.append(
                encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: location.name, encryptionType: message.encryptionType).map{
                    location.name = $0
                    return $0
                }
            )
        }
        
        if location.address.isNotEmpty{
            singles.append(
                encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: location.address, encryptionType: message.encryptionType).map{
                    location.address = $0
                    return $0
                }
            )
        }
        
        
        singles.append(
            encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: String(location.lat), encryptionType: message.encryptionType).map{
                location.latStr = $0
                return $0
            }
        )
        
        singles.append(
            encryptionHelper.encrypt(singleUidOrMultiple: uidToEncryptTo, message: String(location.lng), encryptionType: message.encryptionType).map{
                location.lngStr = $0
                return $0
            }
        )
        
   
        return Single.zip(singles).map{ _ in
            return location
        }
        
        
    }
    
    
    
}
