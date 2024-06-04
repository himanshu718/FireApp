//
//  FireCall.swift
//  FireApp
//
//  Created by Devlomi on 11/7/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift

class FireCall: Object {

    override static func primaryKey() -> String? {
        return "callId"
    }

    @objc dynamic var callId = ""
    @objc dynamic var user: User?
    @objc dynamic private var direction = 0
    @objc dynamic private var type = 0
    @objc dynamic var channel = ""
    @objc dynamic var callUUID = ""

    var callDirection: CallDirection {
        get {
            return CallDirection(rawValue: direction)!
        }
        set {
            direction = newValue.rawValue
        }
    }
    
    var callType: CallType {
          get {
              return CallType(rawValue: type)!
          }
          set {
              type = newValue.rawValue
          }
      }

    @objc dynamic var timestamp = 0
    @objc dynamic var duration = 0
    @objc dynamic var phoneNumber = ""
    @objc dynamic var isVideo = false

    convenience init(callId: String,callUUID:String, user: User?, callType: CallType,callDirection:CallDirection,channel:String, timestamp: Int, duration: Int, phoneNumber: String, isVideo: Bool) {
        self.init()

        self.callId = callId
        self.callUUID = callUUID
        self.user = user
        self.callType = callType
        self.callDirection = callDirection
        self.channel = channel
        self.timestamp = timestamp
        self.duration = duration
        self.phoneNumber = phoneNumber
        self.isVideo = isVideo
    }
    
    
}
