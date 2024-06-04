//
//  BackupFetcher.swift
//  FireApp
//
//  Created by Devlomi on 4/5/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

class BackupFetcher {
     func fetchBackup() -> Single<BackupDB?>{
        return FireConstants.backupRef.child(FireManager.getUid()).rx.observeSingleEvent(.value).map{snapshot in
            if  snapshot.exists(),
               let dict = snapshot.value as? Dictionary<String, AnyObject>{
                let time = dict["time"] as? Int ?? 0
                let password = dict["password"] as? String ?? ""
                let mediaTypes = (dict["mediaTypes"] as? String ?? "").split(separator: ",").map{Int($0)!}
                let fileSize = dict["fileSize"] as? Int ?? 0
                
                let mediaTypesList = List<Int>()
                mediaTypesList.append(objectsIn: mediaTypes)
                
                let backup = BackupDB()
                backup.backupTime = time
                backup.mediaTypes = mediaTypesList
                backup.encryptedPassword = password
                backup.fileSize = fileSize
                
                return backup
            }
            return nil
        }.do (onNext: {(backup) in
            if let backup = backup{
                RealmHelper.getInstance(appRealm).saveObjectToRealm(object: backup)
            }
        })

    }
}
