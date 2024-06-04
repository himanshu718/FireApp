//
//  GroupAuthorView.swift
//  FireApp
//
//  Created by Devlomi on 11/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class GroupAuthorView: UIView ,NibLoadable{
    @IBOutlet weak var container:UIView!
    @IBOutlet weak var label:UILabel!

    override init(frame: CGRect) {
         super.init(frame: frame)
         setupFromNib()
     }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setupFromNib()

     }
    
}
