//
//  SentBaseCell.swift
//  FireApp
//
//  Created by Devlomi on 9/7/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//
import UIKit


class SentBaseCell: BaseCell {


    @IBOutlet weak var stateImage: UIImageView!



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
    override var isInSelectMode: Bool {
        didSet {
            selectBtn.isHidden = !isInSelectMode
        }
    }




    override func bind(message: Message, user: User) {
        super.bind(message: message, user: user)
        stateImage.image = StateImageHelper.getStateImage(state: message.messageState)

        if replyView != nil && message.quotedMessage != nil {
            let colorGreen = Colors.replySentMsgAuthorTextColor
            replyView.container.backgroundColor = Colors.replySentMsgBackgroundColor
            replyView.authorLbl.textColor = colorGreen
            replyView.leftColoredView.backgroundColor = colorGreen
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
            containerView.backgroundColor = Colors.sentMsgBgColor
        }
        
    }


    @objc private func selectTapped() {
        cellDelegate?.didSelectItem(at: indexPath)
    }


}
