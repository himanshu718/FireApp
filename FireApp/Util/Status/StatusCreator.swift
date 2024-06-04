//
//  StatusCreator.swift
//  FireApp
//
//  Created by Devlomi on 11/1/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

class StatusCreator {

    public static func createImageStatus(image: UIImage, thumb: UIImage) -> Status {
        let compressedImage = image.wxCompress()
        let compressedThumbImg = thumb.wxCompress()

        let statusId = Status.getMyStatusRef(type: StatusType.image).childByAutoId().key!
        let thumbImg = compressedThumbImg.toBase64String()
        let file = DirManager.generateFile(type: .SENT_IMAGE)
        try? compressedImage.toData(.medium)?.write(to: file)
        let status = Status()
        status.statusId = statusId
        status.userId = FireManager.getUid()
        status.timestamp = Int(Date().currentTimeMillis())
        status.thumbImg = thumbImg
        status.localPath = file.path
        status.type = .image



        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: status)
        return status
    }

    public static func createVideoStatus(videoUrl: URL) -> Status {



        let assetUrl: AVURLAsset = AVURLAsset.init(url: URL(fileURLWithPath: videoUrl.path), options: nil)

        let videoImage = VideoUtil.generateThumbnail(path: assetUrl.url)!.wxCompress()

        let thumbImg = videoImage.resized(to: CGSize(width: 200, height: 200)).wxCompress().toBase64String()

        let duration = assetUrl.duration.seconds * 1000 //convert it to millis

        let statusId = Status.getMyStatusRef(type: StatusType.video).childByAutoId().key!

        let status = Status()
        status.statusId = statusId
        status.userId = FireManager.getUid()
        status.timestamp = Int(Date().currentTimeMillis())
        status.thumbImg = thumbImg
        status.localPath = videoUrl.path
        status.type = .video
        status.duration = Int(duration)




        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: status)

        return status
    }

    public static func createTextStatus(textStatus: TextStatus) -> Status {

        let statusId = Status.getMyStatusRef(type: .text).childByAutoId().key!

        let status = Status(statusId: statusId, userId: FireManager.getUid(), timestamp: Int(Date().currentTimeMillis()), textStatus: textStatus, statusType: .text)


        textStatus.statusId = statusId
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: status)
        return status;
    }
}
