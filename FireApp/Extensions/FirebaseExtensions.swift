//
//  FirebaseExtensions.swift
//  FireApp
//
//  Created by Devlomi on 12/13/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import FirebaseDatabase

import RxSwift

extension DataSnapshot {
    func toUser() -> User {
        let user = User()
        if let postDict = self.value as? Dictionary<String, AnyObject> {
            user.uid = self.key
            user.userName = postDict["name"] as? String ?? ""
            user.photo = postDict["photo"] as? String ?? ""
            user.status = postDict["status"] as? String ?? ""
            user.ver = postDict["ver"] as? String ?? ""
            user.appVer = postDict["appVer"] as? String ?? ""
            user.thumbImg = postDict["thumbImg"] as? String ?? ""
            user.phone = postDict["phone"] as? String ?? ""
        }
        return user
    }
}

