//
//  ShareTableVC.swift
//  FireApp
//
//  Created by Devlomi on 12/13/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import Contacts
class ShareTableVC: BaseTableVC {

    var userDefaults: UserDefaults!


    override func viewDidLoad() {
        super.viewDidLoad()
        userDefaults = UserDefaults(suiteName: Config.groupName)


        doneTapped()


    }

    private func deleteSharedData() {
        let paths = userDefaults?.stringArray(forKey: ShareKeys.filesPathsKey)
        let vcardPaths = userDefaults?.stringArray(forKey: ShareKeys.vcardsPaths)


        if let filePaths = paths {
            for path in filePaths {
                if let url = URL(string: path) {
                    try? url.deleteFile()
                }
            }
        }

        if let vcards = vcardPaths {
            for vcard in vcards {
                if let url = URL(string: vcard) {
                    try? url.deleteFile()
                }
            }
        }

        userDefaults?.removeObject(forKey: ShareKeys.filesPathsKey)
        userDefaults?.removeObject(forKey: ShareKeys.vcardsPaths)
        userDefaults?.removeObject(forKey: ShareKeys.usersIdsKey)
        userDefaults?.removeObject(forKey: ShareKeys.textOrUrlKey)
        

    }

    private func goToRootVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let setupUserVc = storyboard.instantiateViewController(withIdentifier: "RootNavController")
        self.dismiss(animated: true, completion: nil)
        AppDelegate.shared.window?.rootViewController = setupUserVc
        AppDelegate.shared.window?.makeKeyAndVisible()



    }
    @objc func cancelTapped() {
        goToRootVC()
    }

    @objc func doneTapped() {
        
        let paths = userDefaults?.stringArray(forKey: ShareKeys.filesPathsKey)
        let uids = userDefaults?.stringArray(forKey: ShareKeys.usersIdsKey)

        guard let filesPaths = paths, let usersIds = uids else {
            return
        }


        let users = usersIds.map { RealmHelper.getInstance(appRealm).getUser(uid: $0) }.filter({ $0 != nil })

        let pathsUrls = filesPaths.map { URL(string: $0)! }


        let observables = Observable.merge(getFilePathsMessagesObservable(pathsUrls: pathsUrls, users: users), getVcardsObservable(), getTextObservable())

        let downloadManager = DownloadManager(disposeBag: disposeBag)
        let uploadManager = UploadManager(disposeBag: disposeBag, messageEncryptor: MessageEncryptor(encryptionHelper: EncryptionHelper()))
        let requestManager = RequestManager(disposeBag: disposeBag, downloadManager: downloadManager, uploadManager: uploadManager)



        observables.flatMap { Observable.from($0) }.map { messageCreator -> [Message] in

            return users.map { messageCreator.user($0!).build() }
        }.subscribe(onNext: { (messages) in

            for message in messages {
                requestManager.request(message: message, callback: nil,appRealm: appRealm)
            }

        }, onError: { (error) in
                
                self.deleteSharedData()
            }, onCompleted: {
                self.deleteSharedData()
                self.goToRootVC()
            }).disposed(by: self.disposeBag)
    }

    private func getFilePathsMessagesObservable(pathsUrls: [URL], users: [User?]) -> Observable<[MessageCreator]> {
        return Observable.from(pathsUrls).flatMap { url -> Observable<[MessageCreator]> in
            let ext = url.pathExtension.lowercased()

            switch ext {
            case "jpg", "png", "gif":
                if let data = try? Data(contentsOf: url) {
                    let message = MessageCreator(user: nil, type: .SENT_IMAGE,appRealm: appRealm).image(imageData:data)
                    return Observable.from(optional: [message])
                } else {
                    return Observable.empty()
                }

            case "mp4", "mov":
                if ext == "mp4" {
                    
                    let message = MessageCreator(user: nil, type: .SENT_VIDEO,appRealm: appRealm).path(url.path).copyVideo(true, deleteVideoOnComplete: false)

                    return Observable.from(optional: [message])
                } else {

                    let outputUrl = DirManager.generateFile(type: .SENT_VIDEO)
                    return VideoUtil.exportAsMp4Observable(inputUrl: url, outputUrl: outputUrl).map { videoUrl -> [MessageCreator] in
                        let message = MessageCreator(user: nil, type: .SENT_VIDEO,appRealm: appRealm).path(videoUrl.path).copyVideo(false, deleteVideoOnComplete: false)

                        return [message]
                    }
                }

            case "mp3", "wav", "m4r" ,"m4a":

                let message = MessageCreator(user: nil, type: .SENT_AUDIO,appRealm: appRealm).path(url.path)

                return Observable.from(optional: [message])

            default:
                let message = MessageCreator(user: nil, type: .SENT_FILE,appRealm: appRealm).path(url.path)
                return Observable.from(optional: [message])

            }
        }
    }

    private func getVcardsObservable() -> Observable<[MessageCreator]> {



        guard let vcardPaths = userDefaults.stringArray(forKey: ShareKeys.vcardsPaths), vcardPaths.isNotEmpty else {
            return Observable.empty()
        }


        let vcardsUrls = vcardPaths.map { URL(string: $0)! }

        let vcardsStr = vcardsUrls.map { try? String(contentsOfFile: $0.path, encoding: String.Encoding.utf8) }


        return Observable.from(vcardsStr).flatMap { vcard -> Observable<[CNContact]> in
            if let vcardStr = vcard {
                let vcardData = Data(vcardStr.utf8)
                if let contacts = try? CNContactVCardSerialization.contacts(with: vcardData), contacts.isNotEmpty {

                    return Observable.from(optional: contacts)
                }
            }
            return Observable.empty()
        }.map { contacts in

            let contactsFiltered = contacts.filter({$0.phoneNumbers.isNotEmpty})
            let messageCreator = contactsFiltered.map { MessageCreator(user: nil, type: .SENT_CONTACT,appRealm: appRealm).contact($0.toRealmContact()) }
            return messageCreator
        }

    }

    private func getTextObservable() -> Observable<[MessageCreator]> {

        guard let texts = userDefaults.stringArray(forKey: ShareKeys.textOrUrlKey), texts.isNotEmpty else {
            return Observable.empty()
        }

        let messages = texts.map { MessageCreator(user: nil, type: .SENT_TEXT,appRealm: appRealm).text($0) }
        return Observable.from(optional: messages)


    }
}





