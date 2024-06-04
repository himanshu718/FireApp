				//
//  ReceivedBaseCell.swift
//  FireApp
//
//  Created by Devlomi on 11/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class ReceivedBaseCell: BaseCell {

    @IBOutlet weak var groupAuthorView: GroupAuthorView!

    @IBOutlet weak var groupAuthorAndReplyContainer: UIStackView!



    private var selectBtn: UIButton!
    override var isMessageSelected: Bool {
        didSet {
            let imageName = isMessageSelected ? "check_circle" : "circle"
            let image = UIImage(named: imageName)
            if selectBtn != nil {
                selectBtn.setImage(image, for: .normal)
            }
        }
    }
    //if the user enter selection mode
    //we will show check icon
    //otherwise just hide it
    override var isInSelectMode: Bool {
        didSet {

            let transform = isInSelectMode ? CGAffineTransform(translationX: 35, y: 0) : .identity
            UIView.animate(withDuration: 0.2) {
                self.containerView.transform = transform
            }
            selectBtn.isHidden = !isInSelectMode

        }
    }

    
    
    private func getQuotedUserName(message: Message, user: User) -> String {
        if message.fromId == FireManager.getUid() {
            return Strings.you
        }
        
        if let userName = user.getUserNameByIdForGroups(userId:message.fromId){
            return userName
        }
        
        return message.fromPhone
    }
    
    override func bind(message: Message, user: User) {
        super.bind(message: message, user: user)

        if groupAuthorAndReplyContainer != nil {


            let hideStackView = !message.isGroup && message.quotedMessage == nil
            groupAuthorAndReplyContainer.isHidden = hideStackView

        }

        if groupAuthorView != nil {
            groupAuthorView.isHidden = !message.isGroup
            groupAuthorView.label.text = getQuotedUserName(message: message, user: user)
            
        }
        if replyView != nil && message.quotedMessage != nil {

            let blueColor = Colors.replyReceivedMsgAuthorTextColor
            replyView.container.backgroundColor = Colors.replyReceivedMsgBackgroundColor
            replyView.leftColoredView.backgroundColor = blueColor
            replyView.authorLbl.textColor = blueColor
            replyView.messageContent.textColor = .darkGray
            replyView.replyLayoutIcon.tintColor = .darkGray

        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        let imageName = isMessageSelected ? "check_circle" : "circle"
        selectBtn = UIButton()
        selectBtn.setImage(UIImage(named: imageName), for: .normal)
        selectBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectBtn)
        selectBtn.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 12).isActive = true
        selectBtn.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        selectBtn.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)
        selectBtn.isHidden = true

        if setBackgroundColor() {
            containerView.backgroundColor = Colors.receivedMsgBgColor
        }
        

    }


    @objc private func selectTapped() {
        cellDelegate?.didSelectItem(at: indexPath)
    }


}

