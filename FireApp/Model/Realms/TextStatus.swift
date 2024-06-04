//
//  TextStatus.swift
//  FireApp
//
//  Created by Devlomi on 10/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class TextStatus: Object {
    
    override static func primaryKey() -> String? {
        return "statusId"
    }
    
    @objc dynamic var statusId = ""
    @objc dynamic var text = ""
    @objc dynamic var fontName = ""
    @objc dynamic var backgroundColor = ""
    
    convenience init(statusId:String = "",text:String,fontName:String,backgroundColor:String) {
        self.init()
        self.statusId = statusId
        self.text = text
        self.fontName = fontName
        self.backgroundColor = backgroundColor
    }

    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["text"] = text
        dict["fontName"] = fontName
        dict["backgroundColor"] = backgroundColor
        return dict
    }
}
