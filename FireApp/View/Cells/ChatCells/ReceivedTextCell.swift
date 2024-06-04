//
//  RecivedTextCellTableViewCell.swift
//  FireApp
//
//  Created by Devlomi on 5/29/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class ReceivedTextCell: ReceivedBaseCell {
    
    
    @IBOutlet weak var textView: UITextView!
 
    


    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    override func bind(message: Message,user:User) {
        super.bind(message: message,user:user)
        textView.text  = message.content
    }
    
    
}
