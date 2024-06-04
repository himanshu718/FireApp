//
//  BackupEncryptUtil.swift
//  FireApp
//
//  Created by Devlomi on 3/27/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RNCryptor
import RxSwift

struct BackupEncryptUtil {
    let password: String
    let sourceURL: URL
    let destiniationUrl: URL
    
    private var saltedPassword: String {
        return password + Config.salt
    }
    
    func encrypt() -> Completable {
        return Completable.create { (observer) -> Disposable in
            do {
                let encryptor = RNCryptor.Encryptor(password: saltedPassword)
                let data = try Data(contentsOf: sourceURL)
                
                try autoreleasepool {
                    let newData = encryptor.update(withData: data)
                    try newData.write(to: destiniationUrl)
                }


                let fileHandle = try FileHandle(forWritingTo: destiniationUrl)
                fileHandle.seekToEndOfFile()
                fileHandle.write(encryptor.finalData())
                fileHandle.closeFile()
                observer(.completed)

            }
            catch {
                observer(.error(error))
            }

            return Disposables.create()
        }

  
    }

    func decrypt() ->Completable {
        return Completable.create { (observer) -> Disposable in
            do{
                let encryptedData = try Data(contentsOf: sourceURL)
                let decryptor = RNCryptor.Decryptor(password: saltedPassword)
                try autoreleasepool{
                    let newData = try decryptor.update(withData: encryptedData)
                    try newData.write(to: destiniationUrl)
                }
                
                let fileHandle = try FileHandle(forWritingTo: destiniationUrl)
                fileHandle.seekToEndOfFile()
                try fileHandle.write(decryptor.finalData())
                fileHandle.closeFile()
                observer(.completed)
                
            }catch{
                observer(.error(error))
            }
        
            
            return Disposables.create()
        }
  


    }
}
