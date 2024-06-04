//
//  MediaSaver.swift
//  FireApp
//
//  Created by Devlomi on 3/15/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit

class MediaSaver {
    public static func saveMediaToSave() {

        var customAlbum: CustomAlbum?
        let mediaToSave = RealmHelper.getInstance(appRealm).getMediaToSave()

        if !mediaToSave.isEmpty {
            customAlbum = CustomAlbum(name: Config.appName)
        }

        for media in mediaToSave {
            let url = URL(fileURLWithPath: media.path)

            if media.isVideo {
                customAlbum?.save(videoUrl: url, nil)
            } else {
                if let image = UIImage(contentsOfFile: url.path) {
                    customAlbum?.save(image: image, nil)
                }
            }

        }

        RealmHelper.getInstance(appRealm).deleteMediaToSave()


    }
}
