//
//  BackupResotreRepo.swift
//  FireApp
//
//  Created by Devlomi on 4/1/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

struct BackupRestoreRepo {

    func addSuccessType(mediaType: MessageType) {
        DispatchQueue.main.async {
            if let backup = getBackup() {
                if !backup.successTypes.contains(mediaType.rawValue) {
                    try? appRealm.safeWrite {
                        backup.successTypes.append(mediaType.rawValue)
                    }
                }
            }
        }

    }

    func getBackup() -> BackupDB? {
        return appRealm.objects(BackupDB.self).first
    }
    
    func getUnCompletedMediaType() -> [Int] {
        if let backup = getBackup() {
            let set = Set(backup.mediaTypes)

            let unique = set.subtracting(backup.successTypes)
            let result = Array(unique)

            return result
        }
        return []
    }


    func updateTime(time: Int) {
        DispatchQueue.main.async {
            if let backup = getBackup() {
                try? appRealm.safeWrite {
                    backup.backupTime = time
                }
            }
        }
    }
  
    func updatePassword(_ password: String) {
        DispatchQueue.main.async {
            if let backup = self.getBackup() {
                try? appRealm.safeWrite {
                    backup.password = password
                }
            }
        }
    }

    func updateDownloadedBytes(downlaodedBytes: Int) {
        DispatchQueue.main.async {
            
        
        if let backup = getBackup() {
            try? appRealm.safeWrite {
                backup.downloadedBytes += downlaodedBytes
            }
        }
        }
    }

    func setIsInProgress(_ bool: Bool) {
        DispatchQueue.main.async {
            if let backup = self.getBackup() {
                try? appRealm.safeWrite {
                    backup.isInProgress = bool
                }
            }
        }

    }


    func saveIfNotExistsOrUpdate(backup: BackupDB) {
        DispatchQueue.main.async {
            try? appRealm.safeWrite {

            if let storedBackup = getBackup(){
                storedBackup.password = backup.password
                storedBackup.mediaTypes = backup.mediaTypes
                storedBackup.fileSize = backup.fileSize
                storedBackup.isInProgress = true
            }else{
                    appRealm.add(backup, update: .modified)
                }
            }
        }
    }
    
    func saveIfNotExistsOrUpdateNoDispatch(backup: BackupDB) {
        
            try? appRealm.safeWrite {

            if let storedBackup = getBackup(){
                storedBackup.password = backup.password
                storedBackup.mediaTypes = backup.mediaTypes
                storedBackup.fileSize = backup.fileSize
                storedBackup.isInProgress = true
            }else{
                    appRealm.add(backup, update: .modified)
                }
            }
        
    }
    
    
    func resetAfterComplete()  {
        DispatchQueue.main.async {
            if let backup = getBackup(){
                try? appRealm.safeWrite {
                    backup.downloadedBytes = 0
                    backup.encryptedPassword = ""
                    backup.fileSize = 0
                    backup.mediaTypes = List<Int>()
                    backup.successTypes = List<Int>()
                    backup.isInProgress = false
                    
                }
            }
        }
    }

    func delete() {
        DispatchQueue.main.async {
            if let backup = getBackup() {
                try? appRealm.safeWrite {
                    appRealm.delete(backup)
                }
            }
        }
    }
}
