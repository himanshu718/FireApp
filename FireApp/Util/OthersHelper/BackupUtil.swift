//
//  BackupUtil.swift
//  FireApp
//
//  Created by Devlomi on 3/24/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import ZIPFoundation
import RxSwift
import FirebaseStorage
import FirebaseDatabase

class BackupUtil {

    let progressSubject = BehaviorSubject<Int64>(value: 0)
    let backupFolder = DirManager.getBackupFolder()
    private let backupRestoreRepo = BackupRestoreRepo()
    private static var jobIdDict = [String: Int]()


    static func isWorkRunning() -> Bool {
        return jobIdDict.isNotEmpty
    }



    func backup(password: String, mediaTypes: [MessageType], allItemsSize: Int) -> Completable {
        let id = UUID().uuidString
        BackupUtil.beginBackgroundTask(id: id)
        backupRestoreRepo.setIsInProgress(true)
        
        let observable = Observable.from(mediaTypes).flatMap { mediaItem -> Single<BackupData> in
            return self.zip(mediaItem: mediaItem).map { BackupData(mediaType: mediaItem, fileUrl: $0) }
        }.flatMap { backupData -> Single<BackupData> in
            return self.encrypt(mediaItem: backupData.mediaType, archiveFile: backupData.fileUrl, password: password).map { BackupData(mediaType: backupData.mediaType, fileUrl: $0) }
        }.flatMap { backupData -> Observable<BackupData> in

            return self.upload(file: backupData.fileUrl).map { _ in
                return backupData
            }
                .do(onNext: { backupData in
                    let fileSize = FileUtil.sizeForLocalFilePath(filePath: backupData.fileUrl.path)
                    self.backupRestoreRepo.updateDownloadedBytes(downlaodedBytes: Int(fileSize))
                    self.backupRestoreRepo.addSuccessType(mediaType: backupData.mediaType)
                })
        }



        return Completable.create { (observer) -> Disposable in
            let dis = observable.subscribe { (_) in

            } onError: { (error) in
                observer(.error(error))
            } onCompleted: {
                self.encryptAndUploadDBFile(password: password).flatMap { _ in
                    return self.saveBackupDataToDb(selectedItems: mediaTypes, password: password, allItemsSize: allItemsSize)
                }.subscribe { (_) in
                    observer(.completed)
                } onError: { (error) in
                    observer(.error(error))
                }
            }


            return Disposables.create {
                self.dispose()
                dis.dispose()
            }
        }.do { (error) in
            self.backupRestoreRepo.setIsInProgress(false)
            BackupUtil.endBackgroundTask(id: id)
        } onCompleted: {
            
            self.backupRestoreRepo.updateTime(time: Int(Date().currentTimeMillis()))
            self.backupRestoreRepo.resetAfterComplete()
            BackupUtil.endBackgroundTask(id: id)
            self.backupFolder.deleteFileNotThrows()
            
        }.do(onDispose: {
            self.dispose()
        })

    }
   

    private func dispose() {
        DispatchQueue.main.async {
            let uncompletedTypes = self.backupRestoreRepo.getUnCompletedMediaType().map { MessageType(rawValue: $0)! }
            for mediaType in uncompletedTypes {
                let file = MediaBackupUtil.getFileNameByMediaType(mediaType: mediaType).appending("_enc.zip")
                URL(fileURLWithPath: file).deleteFileNotThrows()

            }
            self.backupRestoreRepo.setIsInProgress(false)
            BackupUtil.endBackgroundTask()

        }
    }

    private func encryptAndUploadDBFile(password: String) -> Single<URL> {
        let dbFile = backupFolder.appendingPathComponent("db.fbup")
        dbFile.deleteFileNotThrows()

        let encryptedDb = backupFolder.appendingPathComponent("db.fbup_enc")
        encryptedDb.deleteFileNotThrows()

        return writeRealmToFile(file: dbFile)
            .andThen(
                BackupEncryptUtil(password: password, sourceURL: dbFile, destiniationUrl: encryptedDb)
                    .encrypt().andThen(
                        upload(file: encryptedDb).asSingle().map { _ in
                            return encryptedDb
                        }
                    )
            )
    }





    private func writeRealmToFile(file: URL) -> Completable {
        return Completable.create { (observer) -> Disposable in
            DispatchQueue.main.async {
                file.deleteFileNotThrows()
                do {
                    try appRealm.writeCopy(toFile: file)
                    observer(.completed)
                }
                catch {
                    observer(.error(error))
                }

            }

            return Disposables.create()
        }

    }
    private func saveBackupDataToDb(selectedItems: [MessageType], password: String, allItemsSize: Int) -> Single<DatabaseReference> {
        let encryptedPassword = PasswordEncryptor(password: password).encrypt()
        
        let mediaTypesJoined = selectedItems.isEmpty ? "" : selectedItems.map { String($0.rawValue) }.joined(separator: ",")
        let ref = FireConstants.backupRef.child(FireManager.getUid())

        var data = [String: Any]()
        data["password"] = encryptedPassword
        data["time"] = ServerValue.timestamp()
        data["fileSize"] = allItemsSize
        data["mediaTypes"] = mediaTypesJoined

        return ref.rx.updateChildValues(data)

    }


    private func upload(file: URL) -> Observable<StorageMetadata> {
        let ref = FireConstants.backupStorageRef.child(FireManager.getUid()).child(file.lastPathComponent)
        return putFileWithProgress(ref: ref, from: file)
    }






    private func encrypt(mediaItem: MessageType, archiveFile: URL, password: String) -> Single<URL> {
        let folderNameByMediaType = MediaBackupUtil.getFileNameByMediaType(mediaType: mediaItem)

        let encryptedFile = archiveFile.deletingLastPathComponent().appendingPathComponent("\(folderNameByMediaType)_enc.zip")
        encryptedFile.deleteFileNotThrows()
        return BackupEncryptUtil(password: password, sourceURL: archiveFile, destiniationUrl: encryptedFile).encrypt()
            .do(onCompleted: {
                archiveFile.deleteFileNotThrows()
            }).andThen(Single.just(encryptedFile))

    }

    private func zip(mediaItem: MessageType) -> Single<URL> {

        return Single<URL>.create { (observer) -> Disposable in
            let folder = MediaBackupUtil.getFolderToZipByMediaType(mediaType: mediaItem)
            let folderNameByMediaType = MediaBackupUtil.getFileNameByMediaType(mediaType: mediaItem)
            let archiveFile = self.backupFolder.appendingPathComponent(folderNameByMediaType).appendingPathExtension("zip")
            
            //create folder if not exists
            DirManager.getBackupFolder()
            
            //delete old files if any
            archiveFile.deleteFileNotThrows()
            guard let archive = Archive(url: archiveFile, accessMode: .create) else {
                observer(.error(NSError(domain: "archive is nil", code: -2, userInfo: nil)))
                return Disposables.create()
            }

            if let files = try? FileManager.default.contentsOfDirectory(atPath: folder.path) {
                for file in files {

                    let url = folder.appendingPathComponent(file)
                    if !url.isDirectory {
                        try? archive.addEntry(with: file, relativeTo: url.deletingLastPathComponent())
                    }

                }
                observer(.success(archiveFile))

            } else {
                observer(.error(NSError(domain: "error unzip", code: -1)))
            }

            return Disposables.create()
        }





    }

    private func getMediaArchives(mediaItems: [MessageType], backupFolder: URL, password: String) -> Single<[URL]> {


        return Observable.from(mediaItems).flatMap { mediaItem -> Observable<URL> in
            let folder = MediaBackupUtil.getFolderToZipByMediaType(mediaType: mediaItem)
            let folderNameByMediaType = MediaBackupUtil.getFileNameByMediaType(mediaType: mediaItem)
            let archiveFile = backupFolder.appendingPathComponent(folderNameByMediaType).appendingPathExtension("zip")
            //delete old files if any
            archiveFile.deleteFileNotThrows()
            guard let archive = Archive(url: archiveFile, accessMode: .create) else {
                throw NSError(domain: "archive is nil", code: -2, userInfo: nil)
            }

            if let files = try? FileManager.default.contentsOfDirectory(atPath: folder.path) {
                for file in files {

                    let url = folder.appendingPathComponent(file)
                    if !url.isDirectory {
                        try archive.addEntry(with: file, relativeTo: url.deletingLastPathComponent())
                    }

                }
                let encryptedFile = archiveFile.deletingLastPathComponent().appendingPathComponent("\(folderNameByMediaType)_enc.zip")
                encryptedFile.deleteFileNotThrows()
                return BackupEncryptUtil(password: password, sourceURL: archiveFile, destiniationUrl: encryptedFile).encrypt()
                    .do(onCompleted: {
                        archiveFile.deleteFileNotThrows()
                    }).andThen(Observable.just(encryptedFile))


            }
            return Observable.empty()
        }.toArray()




    }


    private func putFileWithProgress(ref: StorageReference, from url: URL, metadata: StorageMetadata? = nil) -> Observable<StorageMetadata> {
        return Observable.create { observer in
            let task = ref.putFile(from: url, metadata: metadata) { metadata, error in
                guard let error = error else {
                    if let metadata = metadata {
                        observer.onNext(metadata)
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



fileprivate struct BackupData {
    let mediaType: MessageType
    let fileUrl: URL
}
