//
//  LocalizableButton.swift
//  FireApp
//
//  Created by Devlomi on 1/8/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
class LocalizableButton: UIButton,LocalizableView {
    @IBInspectable var translationKey: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let key = translationKey{
            titleLabel?.text = key.localizedStr
        }
    }
}
