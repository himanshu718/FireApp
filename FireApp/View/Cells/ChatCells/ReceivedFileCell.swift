//
//  ReceivedFileCell.swift
//  FireApp
//
//  Created by Devlomi on 11/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class ReceivedFileCell: ReceivedBaseCell {

    @IBOutlet weak var fileName:UITextView!
     @IBOutlet weak var fileExtPreview:UIView!
     @IBOutlet weak var fileExtensionLbl:UILabel!
    @IBOutlet weak var fileExtensionPreviewLbl:UILabel!
     @IBOutlet weak var fileSizeLbl:UILabel!


    override func bind(message: Message,user:User) {
        super.bind(message: message,user:user)

         fileName.text = message.metatdata
         fileExtensionLbl.text = message.metatdata.fileExtension()
         fileExtensionPreviewLbl.text = message.metatdata.fileExtension().uppercased()
         fileSizeLbl.text = message.fileSize
         fileExtPreview.isHidden = message.downloadUploadState != .SUCCESS
     }
    
}
