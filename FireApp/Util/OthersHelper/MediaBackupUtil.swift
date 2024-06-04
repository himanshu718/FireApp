//
//  MediaBackupUtil.swift
//  FireApp
//
//  Created by Devlomi on 4/9/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
class MediaBackupUtil {
    
    
    func getMediaTypeData() -> [MediaTypeBackupData] {
        let mediaFiles = RealmHelper.getInstance(appRealm).getAllMedia()

        let mediaTypeFileSize = mediaFiles.filter { $0.localPath != "" }.map { (message) -> MediaTypeBackupData in
            let localPath = message.localPath

            let fileSize = Int(FileUtil.sizeForLocalFilePath(filePath: localPath))
            return MediaTypeBackupData(type: message.typeEnum, size: fileSize)
        }

        var dict = [Int: Int]()

        for mediaType in mediaTypeFileSize {
            let id = mediaType.type.rawValue

            let previousFileSize = dict[id] ?? 0
            dict[id] = previousFileSize + mediaType.size
        }

        return dict.map { MediaTypeBackupData(type: MessageType(rawValue: $0)!, size: $1) }


    }
    
    
    static func getFileNameByMediaType(mediaType: MessageType) -> String {
        switch mediaType {
        case .SENT_IMAGE:
            return "SentImages"

        case .RECEIVED_IMAGE:
            return "ReceivedImages"

        case .SENT_VIDEO:
            return "SentVideos"

        case .RECEIVED_VIDEO:
            return "ReceivedVideos"

        case .SENT_VOICE_MESSAGE:
            return "SentVoiceMessages"

        case .RECEIVED_VOICE_MESSAGE:
            return "ReceivedVoiceMssages"

        default:
            return "Unknown"
        }
    }

    static func getFolderToZipByMediaType(mediaType: MessageType) -> URL {
        switch mediaType {
        case .SENT_IMAGE:
            return DirManager.getSentImageFolder()
        case .RECEIVED_IMAGE:
            return DirManager.getReceivedImageFolder()
        case .SENT_VIDEO:
            return DirManager.getSentVideoFolder()
        case .RECEIVED_VIDEO:
            return DirManager.getReceivedVideoFolder()

        case .SENT_VOICE_MESSAGE:
            return DirManager.getSentVoiceFolder()

        case .RECEIVED_VOICE_MESSAGE:
            return DirManager.getReceivedVoiceFolder()

        default:
            return DirManager.getSentFileFolder()
        }
    }
}

struct MediaTypeBackupData {
    let type: MessageType
    let size: Int
}
