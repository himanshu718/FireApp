//
//  PKPwEncryptUtil.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import VirgilE3Kit
class PKPwEncryptUtil {
    private static let passwordCharacters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
    private static let key = "3@4S^&sq_z"

    static func generatePKPwd() throws -> String {
        var ranUUID = UUID().uuidString
        ranUUID = String(ranUUID.dropLast(ranUUID.count/2))

        let rndPswd = String((0..<32).compactMap{ _ in passwordCharacters.randomElement() })+ranUUID
        
        
        if let encrypted = CryptLib().encryptPlainTextRandomIV(withPlainText: rndPswd, key: key){

            return try EThree.derivePasswords(from: encrypted).backupPassword
        }
        
        throw NSError(domain: "Error generatingPKPwd", code: -1, userInfo: nil)
    }


}
