//
//  RestoreBackupUtil.swift
//  FireApp
//
//  Created by Devlomi on 3/30/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseStorage
import RealmSwift

class RestoreBackupUtil {

    let progressSubject = BehaviorSubject<Int64>(value: 0)

    private let backupFolder = DirManager.getBackupFolder()
    private let encryptedDbName = "db.fbup_enc"
    private static var jobIdDict = [String: Int]()


    static func isWorkRunning() -> Bool {
        return jobIdDict.isNotEmpty
    }


    fileprivate func downloadFile(_ mediaItem: MessageType) -> Observable<RestoreData> {
        let fileNameByMediaType = MediaBackupUtil.getFileNameByMediaType(mediaType: mediaItem)
        let encryptedFileName = fileNameByMediaType + "_enc.zip"

        let ref = FireConstants.backupStorageRef.child(FireManager.getUid()).child(encryptedFileName)
        let fileUrl = backupFolder.appendingPathComponent(encryptedFileName)

        return self.downloadWithProgress(ref: ref, toFile: fileUrl).map {
            return RestoreData(downloadedUrl: $0, mediaType: mediaItem, fileNameByMediaType: fileNameByMediaType, encryptedFileName: encryptedFileName, downlaodedBytes: Int(FileUtil.sizeForLocalFilePath(filePath: fileUrl.path)))
        }
    }

    fileprivate func decrypt(password: String, restoreData: RestoreData) -> Observable<RestoreData> {
        let fileUrl = restoreData.downloadedUrl
        let fileNameByMediaType = restoreData.fileNameByMediaType
        let dest = self.backupFolder.appendingPathComponent(fileNameByMediaType).appendingPathExtension("zip")
        dest.deleteFileNotThrows()


        return BackupEncryptUtil(password: password, sourceURL: fileUrl, destiniationUrl: dest).decrypt()
            .andThen(Observable.just(restoreData))
            .flatMap { _ -> Observable<RestoreData> in
                fileUrl.deleteFileNotThrows()
                var newRestoreData = restoreData
                newRestoreData.decryptedUrl = dest
                return Observable.just(newRestoreData)
            }.do(onError: { error in
                dest.deleteFileNotThrows()
            })

    }



    fileprivate func unzip(_ restoreData: RestoreData) -> Completable {
        let decryptedFile = restoreData.decryptedUrl!
        let folder = MediaBackupUtil.getFolderToZipByMediaType(mediaType: restoreData.mediaType)
        return UnZipBackup().unZip(sourceFile: decryptedFile, destinationFolder: folder)
    }

    func restore(password: String, mediaTypes: [MessageType]) -> Completable {

        let backupRestoreRepo = BackupRestoreRepo()
        let id = UUID().uuidString
        RestoreBackupUtil.beginBackgroundTask(id: id)
        backupRestoreRepo.setIsInProgress(true)
        UserDefaultsManager.setRestoreInProgress(true)
        

        let observable = Observable.from(mediaTypes).flatMap { mediaItem -> Observable<RestoreData> in
            return self.downloadFile(mediaItem)
        }.flatMap { restoreData -> Observable<RestoreData> in
            return self.decrypt(password: password, restoreData: restoreData)
        }.flatMap { restoreData -> Observable<RestoreData> in
            return self.unzip(restoreData).andThen(Observable.just(restoreData))
        }.do(onNext: { (restoreBackupObj) in
            backupRestoreRepo.addSuccessType(mediaType: restoreBackupObj.mediaType)
            backupRestoreRepo.updateDownloadedBytes(downlaodedBytes: Int(restoreBackupObj.downlaodedBytes))
        })




        return Completable.create { (observer) -> Disposable in

            let dis = observable.subscribe { (_) in

            } onError: { (error) in
                observer(.error(error))
            } onCompleted: {
            
                let ref = FireConstants.backupStorageRef.child(FireManager.getUid()).child(self.encryptedDbName)
                let fileUrl = self.backupFolder.appendingPathComponent(self.encryptedDbName)
                
                let dest = self.backupFolder.appendingPathComponent("db.fbup")

                ref.rx.write(toFile: fileUrl)
                    .asSingle().asCompletable()
                    .andThen(self.restoreDB(password: password, dbFile: fileUrl, destinationUrl: dest))
                    .subscribe {
                        observer(.completed)
                } onError: { (error) in
                        observer(.error(error))
                }

            }
            return Disposables.create {
                self.dispose(backupRestoreRepo: backupRestoreRepo)
                dis.dispose()
            }
        }.do { (error) in
            backupRestoreRepo.setIsInProgress(false)
            RestoreBackupUtil.endBackgroundTask(id: id)

        } onCompleted: {

            RestoreBackupUtil.endBackgroundTask(id: id)
            self.backupFolder.deleteFileNotThrows()
            
            UserDefaultsManager.setRestoreInProgress(false)
            backupRestoreRepo.delete()

        }
            .do(onDispose: {
                self.dispose(backupRestoreRepo: backupRestoreRepo)
            })



    }

    private func dispose(backupRestoreRepo: BackupRestoreRepo) {
        DispatchQueue.main.async {
            let uncompletedTypes = backupRestoreRepo.getUnCompletedMediaType().map { MessageType(rawValue: $0)! }
            for mediaType in uncompletedTypes {
                let file = MediaBackupUtil.getFileNameByMediaType(mediaType: mediaType).appending("_enc.zip")
                URL(fileURLWithPath: file).deleteFileNotThrows()
            }
            backupRestoreRepo.setIsInProgress(false)
            RestoreBackupUtil.endBackgroundTask()

        }
    }


    func restoreDB(password: String, dbFile: URL, destinationUrl: URL) -> Completable {


        let migration = Completable.create { (observer) -> Disposable in
            
            DispatchQueue.main.async {

                
                do {
                    try RestoreDBMigration().migrate(realmFile: destinationUrl)
                    
                    observer(.completed)
                } catch {
                    observer(.error(error))
                }

            }

            return Disposables.create()
        }

        return BackupEncryptUtil(password: password, sourceURL: dbFile, destiniationUrl: destinationUrl).decrypt()
            .do(onError: { (error) in
                destinationUrl.deleteFileNotThrows()
            })
            .andThen(migration)





    }

    func isPasswordValid(password: String, encryptedPassword: String) -> Bool {
        return PasswordEncryptor(password: password).decrypt(encryptedPassword: encryptedPassword) != nil
    }

    private func downloadWithProgress(ref: StorageReference, toFile: URL) -> Observable<URL> {
        return Observable.create { observer in

            let task = ref.write(toFile: toFile) { (url, error) in
                guard let error = error else {
                    if let url = url {
                        observer.onNext(url)
                    }
                    observer.onCompleted()
                    return
                }
                observer.onError(error)
            }

            task.observe(.progress) { (snapshot) in
                if let bytesDownloaded = snapshot.progress?.completedUnitCount {
                    self.progressSubject.onNext(bytesDownloaded)
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    public static func endBackgroundTask(id: String) {
        if let taskId = jobIdDict[id] {
            UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: taskId))
        }

        jobIdDict.removeAll()


    }

    public static func endBackgroundTask() {
        jobIdDict.values.forEach { (taskId) in
            UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: taskId))
        }

        jobIdDict.removeAll()


    }

    public static func beginBackgroundTask(id: String) -> UIBackgroundTaskIdentifier {
        let taskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        jobIdDict[id] = taskId.rawValue
        return taskId
    }


}


struct RestoreData {
    let downloadedUrl: URL
    var decryptedUrl: URL? = nil
    let mediaType: MessageType
    let fileNameByMediaType: String
    let encryptedFileName: String
    let downlaodedBytes: Int

}



