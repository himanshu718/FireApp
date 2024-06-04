//
//  LocalizableLabel.swift
//  FireApp
//
//  Created by Devlomi on 1/7/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
class LocalizableLabel: UILabel, LocalizableView {
    @IBInspectable var translationKey: String?
    @IBInspectable var injectAppName: Bool = false

    override func awakeFromNib() {
        if let key = translationKey {
            if injectAppName {
                self.text = String(format: key.localizedStr, Config.appName)
            } else {
                self.text = key.localizedStr
            }
        }
    }
}
