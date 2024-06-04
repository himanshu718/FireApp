//
//  RoundedButton.swift
//  FireApp
//
//  Created by Devlomi on 11/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 0.5 * self.bounds.size.width
    }
}
