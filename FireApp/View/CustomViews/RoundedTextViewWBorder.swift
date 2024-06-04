//
//  RoundedTextViewWBorder.swift
//  FireApp
//
//  Created by Devlomi on 5/30/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import GrowingTextView
class RoundedTextViewWBorder: GrowingTextView,LocalizableView{

    @IBInspectable var translationKey: String?
    
    override func awakeFromNib() {
        layer.cornerRadius = 18
        layer.borderWidth = 0.3
        layer.borderColor = UIColor.lightGray.cgColor
   
    }
}
