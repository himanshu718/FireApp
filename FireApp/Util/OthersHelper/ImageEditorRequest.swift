//
//  ImageEditorRequest.swift
//  FireApp
//
//  Created by Devlomi on 11/2/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import iOSPhotoEditor

class ImageEditorRequest {
    public static func getRequest(image: UIImage, delegate: PhotoEditorDelegate) -> PhotoEditorViewController {
        let photoEditor = PhotoEditorViewController(nibName: "PhotoEditorViewController", bundle: Bundle(for: PhotoEditorViewController.self))

        //PhotoEditorDelegate
        photoEditor.photoEditorDelegate = delegate

        //The image to be edited
        photoEditor.image = image

        //Stickers that the user will choose from to add on the image

        for item in StickerBundleRetriever.getStickersFromBundle(){
            if let image = UIImage(named: item.path) {
                photoEditor.stickers.append(image)
            }
        }

        photoEditor.hiddenControls = [.share, .clear, .save]

        return photoEditor


    }
}
