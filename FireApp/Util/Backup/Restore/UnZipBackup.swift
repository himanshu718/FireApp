//
//  UnZipBackup.swift
//  FireApp
//
//  Created by Devlomi on 3/30/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import ZIPFoundation
import RxSwift

class UnZipBackup {
    func unZip(sourceFile:URL,destinationFolder:URL) -> Completable  {
        return Completable.create { (observer) -> Disposable in
            do {
                try FileManager.default.unzipItem(at: sourceFile, to: destinationFolder)
                
            } catch  {
                
            }
            observer(.completed)
            return Disposables.create()
        }
     
      
        
    }
}
