//
//  PasswordEncryptor.swift
//  FireApp
//
//  Created by Devlomi on 3/29/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RNCryptor
struct PasswordEncryptor {

    let password: String

    private var saltedPassword: String {
        return password + Config.salt
    }

    func encrypt() -> String {
        let data = saltedPassword.data(using: String.Encoding.utf8)
        let encryptedData = RNCryptor.encrypt(data: data!, withPassword: saltedPassword)
        let encryptedText = encryptedData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        return encryptedText
    }


    func decrypt(encryptedPassword: String) -> String? {


        let dataToDecrypt = Data(base64Encoded: encryptedPassword)


        if let originalData = try? RNCryptor.decrypt(data: dataToDecrypt! as Data, withPassword: saltedPassword) {
            return String(data: originalData, encoding: String.Encoding.utf8)!
        }

        return nil

    }

}
