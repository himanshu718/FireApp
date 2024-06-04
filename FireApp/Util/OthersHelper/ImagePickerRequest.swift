//
//  ImagePickerRequest.swift
//  FireApp
//
//  Created by Devlomi on 10/10/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation

class ImagePickerRequest {
    public static func getRequest(delegate:MTImagePickerControllerDelegate) -> MTImagePickerController {
        let imagePicker = MTImagePickerController.instance
        imagePicker.mediaTypes = [MTImagePickerMediaType.Photo, MTImagePickerMediaType.Video]
        imagePicker.imagePickerDelegate = delegate
        imagePicker.maxCount = 10 // max select count
        imagePicker.defaultShowCameraRoll = true // when set to true would show Camera Roll Album
        imagePicker.source = .Photos

        return imagePicker
    }
    
}
