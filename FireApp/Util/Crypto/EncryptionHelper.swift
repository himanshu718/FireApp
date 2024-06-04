//
//  EncryptionHelper.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift

class EncryptionHelper {
    private let aesCrypto = CryptLib()
    
    
    func encrypt(singleUidOrMultiple:SingleUidOrMultiple,message:String,encryptionType:String) -> Single<String>{
        switch encryptionType {
        case EncryptionType.AES:
            return Single.just(aesCrypto.encryptPlainTextRandomIV(withPlainText: message, key: AESKey.key))
            
        case EncryptionType.E2E:
            if let uids = singleUidOrMultiple.uids{
                return EthreeHelper.encryptMessage(toIds: Array(uids), message: message)
            }else{
                return EthreeHelper.encryptMessage(toId: singleUidOrMultiple.uid!, message: message)
            }
            
        default:
            return Single.just(message)
        }
        
    }

    
}
