//
//  User.swift
//  FireApp
//
//  Created by Devlomi on 5/17/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    
    override static func primaryKey() -> String? {
        return "uid"
    }

    override static func indexedProperties() -> [String] {
        return ["uid"]
    }

    //user id
    @objc dynamic var uid = ""
    //user photo url in server
    @objc dynamic var photo = ""
    //user status
    @objc dynamic var status = ""
    @objc dynamic var phone = ""
    
    @objc dynamic var userLocalPhoto = ""

    @objc dynamic var userName = ""
    @objc dynamic var userType = ""
    @objc dynamic var businessName = ""
    @objc dynamic var address = ""
    @objc dynamic var gender = ""
    @objc dynamic var bio = ""
    @objc dynamic var instagram = ""
    @objc dynamic var facebook = ""
    @objc dynamic var twitter = ""
    @objc dynamic var email = ""
    @objc dynamic var fullName = ""
    @objc dynamic var homeAddress = ""
    
    @objc dynamic var isBlocked = false
    @objc dynamic var appVer = ""
    @objc dynamic var thumbImg = ""
    @objc dynamic var isGroupBool = false
    @objc dynamic var group: Group?
    @objc dynamic var broadcast: Broadcast?
    @objc dynamic var isBroadcastBool = false
    @objc dynamic var isStoredInContacts = false
    @objc dynamic var ver = ""
    @objc dynamic var isDeleted = false
    
    @objc dynamic var deliverPerishable = false
    @objc dynamic var express_pickup = false
    
    @objc dynamic var businessType = ""
    
    @objc dynamic var extra_phone_number = ""
    @objc dynamic var vehicleType = ""
    @objc dynamic var statelist = ""
    @objc dynamic var house_office = ""
    @objc dynamic var netsAvailable = 0
    @objc dynamic var isIdVerified = false
    
    
    
    var properUserName:String{
        return userName.isEmpty ? phone : userName
    }

    override open func isEqual(_ object: Any?) -> Bool {
        if let user = object as? User {
            return self.uid == user.uid
        }
        return false
    }

}

