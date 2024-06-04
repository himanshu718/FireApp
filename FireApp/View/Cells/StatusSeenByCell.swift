//
//  StatusSeenByCell.swift
//  FireApp
//
//  Created by Devlomi on 3/17/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit

class StatusSeenByCell: UITableViewCell {

    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var seenAtLabel: UILabel!


    func bind(statusSeenBy:StatusSeenBy) {
   
        if let user = statusSeenBy.user{
            userImg.image = user.thumbImg.toUIImage()
            userNameLbl.text = user.userName
        }
            
        
        
        let seenAtDate = statusSeenBy.seenAt.toDate()
        seenAtLabel.text = TimeHelper.getTimeAgo(timestamp: seenAtDate)
        
    }




}

