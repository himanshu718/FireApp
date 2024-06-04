//
//  StateImageHelper.swift
//  FireApp
//
//  Created by Devlomi on 9/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
class StateImageHelper {
    static func getStateImage(state: MessageState) -> UIImage {
        var imageName = ""
        var colorTint = Colors.readTagsDefaultChatViewColor
        switch state {
        case .PENDING:
            imageName = "pending"
            break
        case .SENT:
            imageName = "check"
            break

        case.RECEIVED, .READ:
            imageName = "check_read"
            if state == .READ {
                colorTint = Colors.readTagsReadColor
            }

        case .NONE:
            return UIImage()
        }

        return UIImage(named: imageName)!.tinted(with: colorTint)!

    }

    static func setImageForState(imageView: UIImageView, messageState: MessageState) {
        let image = getStateImage(state: messageState)
        imageView.image = image
    }

}
