//
//  JSONUtil.swift
//  FireApp
//
//  Created by Devlomi on 2/28/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import RealmSwift
class JsonUtil {
    //convert json contact numbers to RealmContact object

    static func getPhoneNumbersList(jsonString: String) -> List<PhoneNumber> {

        let data = jsonString.data(using: .utf8)!
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>
            {

                let numbers = jsonDict.keys.map { PhoneNumber(number: $0) }
                let phoneNumbers = List<PhoneNumber>()
                phoneNumbers.append(objectsIn: numbers)
                return phoneNumbers
            }
        } catch let error as NSError {

        }

        return List<PhoneNumber>()
    }


    //convert json location to RealmLocation object
    public static func getRealmLocationFromJson(jsonString: String) -> RealmLocation? {

        let data = jsonString.data(using: .utf8)!
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>
            {

                let lat = jsonDict["lat"] as? Double ?? 0
                let lng = jsonDict["lng"] as? Double ?? 0
                let address = jsonDict["address"] as? String ?? ""
                let name = jsonDict["name"] as? String ?? ""
                
                return RealmLocation(lat: lat, lng: lng, address: address, name: name)
            } else {
                
            }
        } catch let error as NSError {
            
        }

        return nil
    }

}


