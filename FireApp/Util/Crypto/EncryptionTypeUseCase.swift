//
//  EncryptionTypeUseCase.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
struct EncryptionTypeUseCase {
    static func getEncryptionType(message:Message) -> String{
        let encryptionTypeSetting = Config.encryptionType
        if message.isGroup && encryptionTypeSetting != EncryptionType.NONE{
            return EncryptionType.AES
        }
        return encryptionTypeSetting
    }
}
