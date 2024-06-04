//
//  DateHeaderCell.swift
//  FireApp
//
//  Created by Devlomi on 10/15/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class DateHeaderCell: UITableViewCell {
    @IBOutlet weak var timeLbl:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = .clear
    }

    func bind(message:Message) {
        timeLbl.text = TimeHelper.getChatTime(timestamp: message.timestamp.toDate())
    }
 
    
}
