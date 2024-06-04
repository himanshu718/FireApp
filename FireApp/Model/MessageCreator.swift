//
// Created by Devlomi on 2019-07-15.
// Copyright (c) 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import RealmSwift

class MessageCreator {
    private var user: User?
    private var type: MessageType
    private var text: String = ""
    private var path: String = ""
    private var mapImage: UIImage!
    private var imageData: Data!
    private var thumbImg: UIImage?
    private var fromCamera = false
    private var duration = ""
    private var contact: RealmContact?
    private var location: RealmLocation?
    private var quotedMessage: Message?
    private var copyVideo = false
    private var deleteVideoOnComplete = false
    private var appRealm: Realm!

    private var isInSchedulingMode = false
    private convenience init() {
        self.init()
    }

    init(user: User?, type: MessageType, appRealm: Realm) {
        self.user = user
        self.type = type
        self.appRealm = appRealm
    }

    func text(_ text: String) -> MessageCreator {
        self.text = text
        return self
    }

    func path(_ path: String) -> MessageCreator {
        self.path = path
        return self
    }

    func image(imageData: Data, thumbImage: UIImage? = nil) -> MessageCreator {
        self.imageData = imageData
        self.thumbImg = thumbImage
        return self
    }
    func video(videoPath: String, thumbImg: UIImage) -> MessageCreator {
        self.path = videoPath
        self.thumbImg = thumbImg
        return self
    }
    func fromCamera(_ fromCamera: Bool) -> MessageCreator {
        self.fromCamera = fromCamera
        return self
    }

    func duration(_ duration: String) -> MessageCreator {
        self.duration = duration
        return self
    }

    func contact(_ contact: RealmContact) -> MessageCreator {
        self.contact = contact
        return self
    }

    func location(_ location: RealmLocation, mapImage: UIImage) -> MessageCreator {
        self.mapImage = mapImage
        self.location = location
        return self
    }

    func quotedMessage(_ quotedMessage: Message?) -> MessageCreator {
        self.quotedMessage = quotedMessage
        return self
    }

    func copyVideo(_ copyVideo: Bool, deleteVideoOnComplete: Bool) -> MessageCreator {
        self.copyVideo = copyVideo
        self.deleteVideoOnComplete = deleteVideoOnComplete
        return self
    }

    func user(_ user: User) -> MessageCreator {
        self.user = user
        return self
    }

    func schedulingMode(bool: Bool) -> MessageCreator {
        self.isInSchedulingMode = bool
        return self
    }

    static func saveNewMessage(_ message: Message, user: User, appRealm: Realm) {
        RealmHelper.getInstance(appRealm).saveDateMessageIfNeeded(message: message)
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: message, update: false)
        RealmHelper.getInstance(appRealm).saveChatIfNotExists(message: message, user: user)
    }

    func build() -> Message {
        let receiverUid = user!.uid
        let message = Message()
        let messageId = FireManager.generateKey()
        message.fromId = FireManager.getUid()
        message.toId = receiverUid
        message.chatId = receiverUid
        message.timestamp = Date().currentTimeMillisLong()
        message.messageState = MessageState.PENDING
        message.downloadUploadState = .LOADING
        message.messageId = messageId
        message.typeEnum = type

        if user!.isGroupBool {
            message.isGroup = true
        }

        if user!.isBroadcastBool {
            message.isBroadcast = true
        }

        switch type {
        case .SENT_TEXT:
            message.content = text
            break

        case .SENT_IMAGE:

            let imageExtension = imageData.imageExtension


            let image = UIImage(data: imageData) ?? UIImage()

            let file = DirManager.generateFile(type: type, fileExtension: imageExtension)

            let compressedImage = image.wxCompress()

            if imageExtension == "gif" {
                try? imageData?.write(to: file)
            } else {
                try? compressedImage.toData(.medium)?.write(to: file)

            }

            if let thumbImg = thumbImg {
                message.thumb = thumbImg.wxCompress().kf.blurred(withRadius: 0.8).toBase64String()
            } else {
                message.thumb = compressedImage.resized(to: CGSize(width: 50, height: 50)).kf.blurred(withRadius: 0.8).toBase64String()
            }

            let fileSize = FileUtil.getFileSize(filePath: file.path)

            message.fileSize = fileSize
            message.metatdata = fileSize
            message.localPath = file.path

            break
            
        case .SENT_STICKER:
            
            let fileSize = FileUtil.getFileSize(filePath: path)
            let newPath = DirManager.generateFile(type: .SENT_STICKER)
            FileUtil.secureCopyItem(at: URL(fileURLWithPath: path), to: newPath)
            message.fileSize = fileSize
            message.metatdata = fileSize
            message.localPath = newPath.path
            break

        case .SENT_VIDEO:

            var file: URL!
            var assetUrl: AVURLAsset!

            let videoUrl: AVURLAsset = AVURLAsset.init(url: URL(fileURLWithPath: path), options: nil)

            if copyVideo {
                file = DirManager.generateFile(type: type)

                FileUtil.secureCopyItem(at: videoUrl.url, to: file)

                assetUrl = AVURLAsset.init(url: URL(fileURLWithPath: file.path), options: nil)

            } else {
                file = URL(fileURLWithPath: path)
                assetUrl = AVURLAsset.init(url: URL(fileURLWithPath: file.path), options: nil)
            }


            let videoImage = VideoUtil.generateThumbnail(path: assetUrl.url)?.wxCompress()

            let duration = CMTimeGetSeconds(assetUrl.duration).timeFormat()

            let videoSize = FileUtil.getFileSize(filePath: assetUrl.url.path)



            let blurredThumb = videoImage?.resized(to: CGSize(width: 50, height: 50)).kf.blurred(withRadius: 0.8).toBase64String()

            message.thumb = blurredThumb ?? ""
            message.videoThumb = videoImage?.toBase64String() ?? ""
            message.metatdata = videoSize
            message.mediaDuration = duration
            message.localPath = file.path

            if deleteVideoOnComplete {
                try? URL(fileURLWithPath: path).deleteFile()
            }
            break


        case .SENT_VOICE_MESSAGE:


            let url = URL(fileURLWithPath: path)

            let fileSize = FileUtil.getFileSize(filePath: path)
            let filePath = url.path

            message.fileSize = fileSize
            message.localPath = filePath
            message.mediaDuration = duration

            break

        case .SENT_CONTACT:
            message.contact = contact
            message.content = contact!.name
            break

        case .SENT_LOCATION:


            guard let location = location else {
                break
            }

            let thumb = mapImage.wxCompress().toBase64String()
            message.thumb = thumb
            message.location = location
            message.content = location.name
            break

        case .SENT_AUDIO:

            let url = URL(fileURLWithPath: path)

            let filePathUrl = DirManager.generateFile(type: .SENT_AUDIO, fileExtension: url.pathExtension)
            FileUtil.secureCopyItem(at: url, to: filePathUrl)
            let fileSize = FileUtil.getFileSize(filePath: filePathUrl.path)


            let filePath = filePathUrl.path

            let asset = AVURLAsset(url: filePathUrl, options: nil)
            let audioDuration = asset.duration
            let audioDurationSeconds = CMTimeGetSeconds(audioDuration)

            let duration = audioDurationSeconds.timeFormat()

            message.localPath = filePath
            message.mediaDuration = duration
            message.metatdata = fileSize

            break

        case .SENT_FILE:
            let url = URL(fileURLWithPath: path)

            let fileName = url.lastPathComponent
            let filePathUrl = DirManager.generateFile(type: .SENT_FILE, fileExtension: url.pathExtension)
            FileUtil.secureCopyItem(at: url, to: filePathUrl)
            let fileSize = FileUtil.getFileSize(filePath: filePathUrl.path)

            let filePath = filePathUrl.path

            message.localPath = filePath
            message.fileSize = fileSize
            message.metatdata = fileName
            break
        default:
            return message

        }
        
        message.encryptionType = EncryptionTypeUseCase.getEncryptionType(message: message)
        
        if let user = user,user.isBroadcastBool, let broadcast = user.broadcast{
            let broadcastUidsArray = broadcast.users.map{$0.uid}
            let broadcastUids = List<String>()
            broadcastUids.append(objectsIn: broadcastUidsArray)
            message.broadcastUids = broadcastUids
        }

        if let quotedMessage = quotedMessage {
            let quotedMessageToSave = QuotedMessage.messageToQuotedMessage(quotedMessage)
            message.quotedMessage = quotedMessageToSave
        }

        //if it's in scheduling mode we don't want to save the message to Messages DB, instead we we want to save to ScheduledMessages DB
        if !isInSchedulingMode {
            MessageCreator.saveNewMessage(message, user: user!, appRealm: appRealm)
        }

        return message
    }
    

    public static func createForwardedMessage(mMessage: Message, user: User, fromId: String, appRealm: Realm) -> Message {
        //clone the original message to modify some of its properties
        let message = Message(value: mMessage)


        let newMessageId = FireManager.generateKey()
        //change messageId
        message.messageId = newMessageId
        //change timestamp
        message.timestamp = Date().currentTimeMillisLong()
        message.isForwarded = true
        //change fromId
        message.fromId = fromId
        //change toId
        message.toId = user.uid

        message.chatId = user.uid
        //convert received type to a sent type if needed
        message.typeEnum = message.typeEnum.convertReceivedToSent()
        message.messageState = .PENDING

        message.isGroup = user.isGroupBool
        message.isBroadcast = user.isBroadcastBool
        if let broadcast = user.broadcast{
            let broadcastUidsArray = broadcast.users.map{$0.uid}
            let broadcastUids = List<String>()
            broadcastUids.append(objectsIn: broadcastUidsArray)
            message.broadcastUids = broadcastUids
        }else{
            message.broadcastUids = List<String>()
        }
        
        message.encryptionType = EncryptionTypeUseCase.getEncryptionType(message: message)

        //copy the file from the message to a New Path
        //this is because when the user deletes a message from a Chat
        //it will not affect the forwarded message
        // since it has a different path with a different file name
        if message.localPath != "" {
            let fileToCopyUrl = URL(fileURLWithPath: message.localPath)

            let forwardedFile = DirManager.generateFile(type: message.typeEnum, fileExtension: fileToCopyUrl.pathExtension)
            FileUtil.secureCopyItem(at: fileToCopyUrl, to: forwardedFile)
            message.localPath = forwardedFile.path
        }

        RealmHelper.getInstance(appRealm).saveDateMessageIfNeeded(message: message)
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: message, update: false)
        RealmHelper.getInstance(appRealm).saveChatIfNotExists(message: message, user: user)
        return message;
    }
}
