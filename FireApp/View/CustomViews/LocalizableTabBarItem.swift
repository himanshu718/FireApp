//
//  LocalizableBarItem.swift
//  FireApp
//
//  Created by Devlomi on 1/7/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
class LocalizableTabBarItem: UITabBarItem, LocalizableView {

    @IBInspectable var translationKey: String?

    override func awakeFromNib() {
        super.awakeFromNib()

        if let key = translationKey {
            title = key.localizedStr
            
        }
    }

}
