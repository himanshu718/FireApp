//
//  RoundedLabel.swift
//  FireApp
//
//  Created by Devlomi on 12/23/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import BadgeSwift
class RoundedLabel: BadgeSwift,LocalizableView{

    @IBInspectable var translationKey: String?

    override func awakeFromNib() {
        if let key = translationKey{
            self.text = key.localizedStr
        }
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = true
        layer.cornerRadius = self.frame.width / 2


    }



}
