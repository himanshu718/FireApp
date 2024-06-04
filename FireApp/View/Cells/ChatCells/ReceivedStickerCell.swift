//
//  ReceivedStickerCell.swift
//  FireApp
//
//  Created by Devlomi on 3/17/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
class ReceivedStickerCell: ReceivedBaseCell {
    private let defaultReplyViewHeight: CGFloat = 50
    private let defaultContainerHeight: CGFloat = 150
    private let defaultGroupAuthorViewHeight: CGFloat = 25

    @IBOutlet weak var timeAndStateView: UIView!
    @IBOutlet weak var replyContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    @IBOutlet weak var groupAuthorViewHeight: NSLayoutConstraint!


    override func setBackgroundColor() -> Bool {
        return false
    }

    @IBOutlet weak var imageContent: UIImageView!



    override func awakeFromNib() {
        super.awakeFromNib()
        timeAndStateView.backgroundColor = Colors.receivedMsgBgColor
        groupAuthorView.backgroundColor = Colors.receivedMsgBgColor
    }




    override func bind(message: Message, user: User) {
        super.bind(message: message, user: user)
        if message.quotedMessage == nil {
            replyContainerHeight.constant = 0 //remove extra space
        } else {
            replyContainerHeight.constant = defaultReplyViewHeight
        }
        
        if message.isGroup{
            containerHeight.constant = defaultContainerHeight + defaultGroupAuthorViewHeight
            groupAuthorViewHeight.constant = defaultGroupAuthorViewHeight
        }else{
            containerHeight.constant = defaultContainerHeight
            groupAuthorViewHeight.constant = 0
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
