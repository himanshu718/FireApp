//
//  ToolbarTitleItem.swift
//  FireApp
//
//  Created by Devlomi on 9/14/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class ToolBarTitleItem: UIBarButtonItem {
    private var label: UILabel!
    var text = "0" {
        didSet {
            label.text = text
            label.sizeToFit()
        }
    }

    init(text: String, font: UIFont, color: UIColor) {
        label = UILabel(frame: UIScreen.main.bounds)
        label.text = "0"
        label.sizeToFit()
        label.font = font
        label.textColor = color
        label.textAlignment = .center
        super.init()
        customView = label
    }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
}
