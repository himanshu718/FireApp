//
//  PhoneContact.swift
//  FireApp
//
//  Created by Devlomi on 9/19/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class PhoneContact {
    var name:String = ""
    var numbers = [String]()
    
    init(name:String,numbers:[String]) {
        self.name = name
        self.numbers = numbers
    }
}
