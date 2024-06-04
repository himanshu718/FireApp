//
//  ContactMapper.swift
//  FireApp
//
//  Created by Devlomi on 6/11/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

struct ContactMapper {
    static let CONTACT_SEPARATOR = ",,,"

    static func mapNumbersToString(numbers: List<PhoneNumber>) -> String{
        return numbers.map{$0.number}.joined(separator: CONTACT_SEPARATOR)
    }
    
    static func mapStringToNumbers(numbersString: String) -> [PhoneNumber] {
        if numbersString.isEmpty{
            return []
        }
        
        

         let foundNumbers = numbersString.components(separatedBy: CONTACT_SEPARATOR)
        
         if (foundNumbers.isEmpty) {
             return []
         }

        return foundNumbers.map { PhoneNumber(number: $0) }
     }
}
