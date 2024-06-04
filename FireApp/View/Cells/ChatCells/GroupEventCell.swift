//
//  GroupEventCell.swift
//  FireApp
//
//  Created by Devlomi on 10/2/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class GroupEventCell: UITableViewCell {
    @IBOutlet weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 12.0
    }
    

    func bind(text: String) {
        textView.text = text
    }
}
