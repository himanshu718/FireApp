//
//  Alerts.swift
//  FireApp
//
//  Created by Devlomi on 12/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
class Alerts {
            static let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
    
    static var videoStatusLongAlert:UIAlertController{
        let alert = UIAlertController(title: Strings.video_is_long, message: nil, preferredStyle: .alert)
        alert.addAction(okAction)
        return alert
    }
    
    static let okAction = UIAlertAction(title: Strings.ok, style: .cancel, handler: nil)

}
