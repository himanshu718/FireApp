//
//  MediaPreviewCell.swift
//  FireApp
//
//  Created by Devlomi on 7/31/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
class MediaPreviewCell: UICollectionViewCell {
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var videoContainer:UIView!
    @IBOutlet weak var videoDurationLbl:UILabel!
    @IBOutlet weak var selectedView:UIView!
    
 
    
    override var isHighlighted: Bool {
        didSet{
            selectedView.isHidden = true
        }
    }
    
    override var isSelected: Bool{
        didSet{
            selectedView.isHidden = !isSelected
        }
    }
    
   
    func bind(message:Message){
        imageView.hero.id = message.messageId
        if message.typeEnum == .SENT_VIDEO || message.typeEnum == .RECEIVED_VIDEO{
            videoContainer.isHidden = false
            videoDurationLbl.text = message.mediaDuration
            imageView.image = message.videoThumb.toUIImage()
        }else if message.typeEnum == .SENT_IMAGE || message.typeEnum == .RECEIVED_IMAGE{
            videoContainer.isHidden = true
            if let image = UIImage(contentsOfFile: message.localPath){
                imageView.image = image
            }
            
        }
    }
    
}
