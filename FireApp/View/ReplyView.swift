//
//  ReplyView.swift
//  FireApp
//
//  Created by Devlomi on 9/17/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

@IBDesignable class ReplyView: UIView, NibLoadable {

    @IBOutlet weak var authorLbl: UILabel!
    @IBOutlet weak var messageContent: UILabel!

    @IBOutlet weak var replyLayoutThumb: UIImageView!
    @IBOutlet weak var replyLayoutIcon: UIImageView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var leftColoredView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()

    }

    func bind(quotedMessage: QuotedMessage, user: User) {


        authorLbl.text = getQuotedUserName(quotedMessage: quotedMessage, user: user)
        messageContent.text = MessageTypeHelper.getMessageContent(message: quotedMessage.toMessage(), includeEmoji: false)

        if quotedMessage.typeEnum.isImage() || quotedMessage.typeEnum.isVideo() || quotedMessage.typeEnum.isStickerType() {
            replyLayoutThumb.isHidden = false
            if quotedMessage.typeEnum.isStickerType() && quotedMessage.localPath != "" {
                replyLayoutThumb.image = UIImage(named: quotedMessage.localPath)
            } else {
                replyLayoutThumb.image = quotedMessage.thumb.toUIImage()
            }
        } else {
            replyLayoutThumb.isHidden = true
        }

        //icon on the left
        if !quotedMessage.typeEnum.isText() && !quotedMessage.typeEnum.isStickerType() {
            let imageName = MessageTypeHelper.getMessageTypeImage(type: quotedMessage.typeEnum)
            replyLayoutIcon.image = UIImage(named: imageName)
            replyLayoutIcon.isHidden = false
        } else {
            replyLayoutIcon.isHidden = true
        }


    }

    private func getQuotedUserName(quotedMessage: QuotedMessage, user: User) -> String {

        var userName = ""
        let fromId = quotedMessage.fromId

        if fromId == FireManager.getUid() {
            userName = Strings.you
        } else {
            if let userNameInGroup = user.getUserNameByIdForGroups(userId: quotedMessage.fromId) {
                userName = userNameInGroup
            } else {

                userName = quotedMessage.fromPhone
            }
        }

        if quotedMessage.status != nil {
            return "\(userName) • \(Strings.status)"
        } else {
            return userName
        }


    }


}

public protocol NibLoadable {
    static var nibName: String { get }
}

public extension NibLoadable where Self: UIView {

    static var nibName: String {
        return String(describing: Self.self) // defaults to the name of the class implementing this protocol.
    }

    static var nib: UINib {
        let bundle = Bundle(for: Self.self)
        return UINib(nibName: Self.nibName, bundle: bundle)
    }

    func setupFromNib() {
        guard let view = Self.nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("Error loading \(self) from nib")
        }
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        view.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        view.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        view.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
}
