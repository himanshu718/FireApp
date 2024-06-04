//
//  SentImageCell.swift
//  FireApp
//
//  Created by Devlomi on 7/11/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import CircleProgressButton
import Kingfisher

class SentImageCell: SentBaseCell {

    @IBOutlet weak var imageContent: UIImageView!


    private var progressDict = [String: Float]()




    override func bind(message: Message, user: User) {
        super.bind(message: message, user: user)

        if message.localPath != "" {
            let url = URL(fileURLWithPath: message.localPath)
            let provider = LocalFileImageDataProvider(fileURL: url)
            imageContent.kf.setImage(
                with: provider,
                placeholder: message.thumb.toUIImage(),
                options: [
                        .processor(DownsamplingImageProcessor(size: imageContent.frame.size)),
                        .scaleFactor(UIScreen.main.scale),
                        .cacheOriginalImage
                ])
        } else {
            let cacheKey = message.messageId + "-thumb"
            let provider = Base64Provider(base64String: message.thumb, cacheKey: cacheKey)
            imageContent.kf.setImage(with: provider)
        }






    }


}
