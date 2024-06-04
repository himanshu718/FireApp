//
//  StringUtils.swift
//  FireApp
//
//  Created by Devlomi on 12/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class StringUtils {
    //this will remove the separators if it's exists at the end of text
    public static func removeExtraSeparators(text: String, separator: String) -> String {


        if let lastChar = text.last,lastChar == " " {
            return String(text.dropLast(3))
        }
       
        return text


    }
}
