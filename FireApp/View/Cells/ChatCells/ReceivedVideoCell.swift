//
//  ReceivedVideoCell.swift
//  FireApp
//
//  Created by Devlomi on 11/23/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import Kingfisher

class ReceivedVideoCell: ReceivedBaseCell {

    @IBOutlet weak var imageContent: UIImageView!


    override func bind(message: Message,user:User) {
        super.bind(message: message,user:user)
        

        
        if !message.videoThumb.isEmpty {
            
            
            
             let cacheKey = message.messageId + "-video-thumb"
            let provider = Base64Provider(base64String: message.videoThumb, cacheKey: cacheKey)

            imageContent.kf.setImage(
            with: provider,
            options: [
                .processor(DownsamplingImageProcessor(size: imageContent.frame.size)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ])
            
        }else{
            
            let cacheKey = message.messageId + "-thumb"
              let provider = Base64Provider(base64String: message.thumb, cacheKey: cacheKey)
              imageContent.kf.setImage(with: provider)
        }


    }

}
