//
//  DecryptionHelper.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift

class DecryptionHelper {
    
    private let aesCrypto = CryptLib()
    
    
    func decrypt(fromId:String,message:String,encryptionType:String) -> Single<String> {
        switch encryptionType {
        case EncryptionType.AES:
            return Single.just(aesCrypto.decryptCipherTextRandomIV(withCipherText: message, key: AESKey.key))
            
        case EncryptionType.E2E:
            return EthreeHelper.decryptMessage(fromId: fromId, encryptedMessage: message)
        default:
            return Single.just(message)
        }
        
    }
}
