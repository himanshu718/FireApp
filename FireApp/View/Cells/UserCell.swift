//
//  UserCell.swift
//  FireApp
//
//  Created by Devlomi on 9/21/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {

    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var userStatusLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func bind(user: User) {
        if user.isBroadcastBool{
            userImg.image = UIImage(named: "rss")

        }else{
            userImg.image = user.thumbImg.toUIImage()
        }
        userNameLbl.text = user.uid == FireManager.getUid() ? Strings.you : user.userName
        userStatusLbl.text = user.status
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    


}

