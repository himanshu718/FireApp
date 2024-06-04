//
//  RealmLocation.swift
//  FireApp
//
//  Created by Devlomi on 5/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class RealmLocation: Object {
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0
    @objc dynamic var address = ""
    @objc dynamic var name = ""
    
    @objc dynamic var latStr = ""
    @objc dynamic var lngStr = ""

    convenience init(lat: Double, lng: Double, address: String, name: String) {
        self.init()
        self.lat = lat
        self.lng = lng
        self.address = address
        self.name = name
    }

    convenience init(lat: String, lng: String, address: String, name: String) {
        self.init()
        self.latStr = lat
        self.lngStr = lng
        self.address = address
        self.name = name
    }

    func toMap(isEncrypted:Bool) -> [String: Any] {
        //TODO TEST NOT ENCRYPTED AND AES LOCATIONS
        var locationMap: [String: Any] = [:]
        let newLat:Any = isEncrypted ? latStr : lat
        let newLng:Any = isEncrypted ? lngStr : lng
        locationMap["lat"] = newLat
        locationMap["lng"] = newLng
        locationMap["address"] = address
        locationMap["name"] = name
        return locationMap
    }

}



