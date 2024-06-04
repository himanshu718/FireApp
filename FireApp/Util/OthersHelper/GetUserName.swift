//
//  GetUserName.swift
//  FireApp
//
//  Created by Devlomi on 3/4/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import UIKit

class GetUserInfo{
    
    static func getUserName(user: User, fromId: String, fromPhone: String) -> String {

        if user.isGroupBool {
            let userName = user.getUserNameByIdForGroups(userId: fromId) ?? fromPhone
            return userName + " @ " + user.userName
        }

        return RealmHelper.getInstance(appRealm).getUser(uid: fromId)?.userName ?? fromPhone

    }
    
    static func getUserThumbImg(user: User, fromId: String) -> String? {

         if user.isGroupBool, let foundUser = user.getUserByIdForGroups(userId: fromId) {
            return foundUser.thumbImg
            
         }

         return RealmHelper.getInstance(appRealm).getUser(uid: fromId)?.thumbImg

     }
}
