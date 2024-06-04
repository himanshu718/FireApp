//
//  RealmContact.swift
//  FireApp
//
//  Created by Devlomi on 5/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
class RealmContact: Object {
    @objc dynamic var name=""
    var realmList = List<PhoneNumber>()
    @objc dynamic var jsonString = ""
    
    convenience init(name:String,numbers:List<PhoneNumber>) {
        self.init()
        self.name = name
        realmList = numbers
    }
    
    func toMap() -> [String : Bool]{
        var numbers : [String : Bool] = [:]
        for number in realmList {
            numbers[number.number] = true
        }
        return numbers
    }
}

