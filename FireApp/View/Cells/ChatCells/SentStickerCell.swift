//
//  SentStickerCell.swift
//  FireApp
//
//  Created by Devlomi on 3/15/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
import Kingfisher
class SentStickerCell: SentBaseCell {
    private let defaultReplyViewHeight: CGFloat = 50

    @IBOutlet weak var timeAndStateView: UIView!
    @IBOutlet weak var replyContainerHeight: NSLayoutConstraint!


    override func setBackgroundColor() -> Bool {
        return false
    }

    @IBOutlet weak var imageContent: UIImageView!



    override func awakeFromNib() {
        super.awakeFromNib()
        timeAndStateView.backgroundColor = Colors.sentMsgBgColor

    }




    override func bind(message: Message, user: User) {
        super.bind(message: message, user: user)
        if message.quotedMessage == nil {
            replyContainerHeight.constant = 0 //remove extra space
        } else {
            replyContainerHeight.constant = defaultReplyViewHeight
        }
        
        if message.localPath != "" {
            let image = UIImage(named: message.localPath)
            imageContent.image = image
        } else {
            let image = UIImage(named: "ic_sticker")
            imageContent.image = image
        }






    }


}
