//
//  SentLocationCell.swift
//  FireApp
//
//  Created by Devlomi on 8/31/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class SentLocationCell: SentBaseCell {

    @IBOutlet weak var locationImage: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func bind(message: Message,user:User) {
        super.bind(message: message,user:user)

        locationImage.image = message.thumb.toUIImage()

    }

}
