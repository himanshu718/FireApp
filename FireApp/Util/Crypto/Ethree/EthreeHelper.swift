//
//  EthreeHelper.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import VirgilE3Kit
import VirgilSDK

class EthreeHelper {
    
    static func encryptMessage(toId:String,message:String) -> Single<String> {
        return EthreeInstance.initialize().flatMap{ethree ->Single<(Card,EThree)> in
            return ethree.findUserRx(with: toId).map{($0,ethree)}
        }.flatMap{(card,ethree) -> Single<String> in
            do {
                let encrypted = try ethree.authEncrypt(text: message, for: card)
                return Single.just(encrypted)
            }catch{
                return Single.error(error)
            }
            
        }
    }
    
    static func encryptMessage(toIds:[String],message:String) -> Single<String> {
        return EthreeInstance.initialize().flatMap{ethree ->Single<(FindUsersResult,EThree)> in
            return ethree.findUsersRx(with: toIds,checkResult: false).map{($0,ethree)}
        }.flatMap{(findUsersResult,ethree) -> Single<String> in
            do {
                let encrypted = try ethree.authEncrypt(text: message, for: findUsersResult)
                return Single.just(encrypted)
            }catch{
                return Single.error(error)
            }
            
        }
    }
    
    static func decryptMessage(fromId:String,encryptedMessage:String) -> Single<String> {
        return EthreeInstance.initialize().flatMap{ethree ->Single<(Card,EThree)> in
            return ethree.findUserRx(with: fromId).map{($0,ethree)}
        }.flatMap{(card,ethree) -> Single<String> in
            do {
                let encrypted = try ethree.authDecrypt(text: encryptedMessage, from: card)
                return Single.just(encrypted)
            }catch{
                return Single.error(error)
            }
            
        }
    }
}
