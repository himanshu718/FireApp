//
//  Status.swift
//  FireApp
//
//  Created by Devlomi on 10/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseDatabase

class Status: Object {

    override static func primaryKey() -> String? {
        return "statusId"
    }

    override static func indexedProperties() -> [String] {
        return ["userId"]
    }

    @objc dynamic var statusId = ""
    @objc dynamic var userId = ""
    @objc dynamic var timestamp = 0
    @objc dynamic var thumbImg = ""
    @objc dynamic var content = ""
    @objc dynamic var localPath = ""
    @objc dynamic var textStatus: TextStatus?
    @objc dynamic private var statusType = 1
     var statusSeenBy = List<StatusSeenBy>()

    var type: StatusType {
        get {
            return StatusType(rawValue: statusType)!
        }
        set {
            statusType = newValue.rawValue
        }
    }
    @objc dynamic var duration = 0
    //this is for the user when he uploads a status and wants to see how many people saw that status
    @objc dynamic var seenCount = 0
    //this is for other users when they saw a status we want to make a job to update it on Firebase
    @objc dynamic var seenCountSent = false
    @objc dynamic var isSeen = false

    convenience init(statusId: String, userId: String, timestamp: Int, thumbImg: String = "", content: String = "", localPath: String = "", textStatus: TextStatus, statusType: StatusType) {
        self.init()
        self.statusId = statusId
        self.userId = userId
        self.timestamp = timestamp
        self.thumbImg = thumbImg
        self.content = content
        self.localPath = localPath
        self.textStatus = textStatus
        self.type = statusType
    }
    override func isEqual(_ object: Any?) -> Bool {
        if let status = object as? Status {
            return status.statusId == statusId
        }
        return false
    }

    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["timestamp"] = ServerValue.timestamp()
        dict["type"] = type.rawValue
        dict["duration"] = duration


        if let textStatus = textStatus {
            let textStatusDict = textStatus.toDict()
            for key in textStatusDict.keys {
                dict[key] = textStatusDict[key]
            }

        } else {
            dict["thumbImg"] = thumbImg
            dict["content"] = content
        }
        return dict
    }

    static func getMyStatusRef(type: StatusType) -> DatabaseReference {

        if (type == StatusType.text) {
            return FireConstants.textStatusRef.child(FireManager.getUid())
        } else {
            return FireConstants.statusRef.child(FireManager.getUid())
        }

    }
}



enum StatusType: Int {
    case image = 1
    case video = 2
    case text = 3
}
extension DataSnapshot {

    func toStatus() -> Status {
        let status = Status()
        if let statusDict = self.value as? Dictionary<String, AnyObject> {
            let statusId = self.key
            status.statusId = statusId
            status.userId = self.ref.parent!.key!
            status.content = statusDict["content"] as? String ?? ""
            status.duration = statusDict["duration"] as? Int ?? 0
            status.thumbImg = statusDict["thumbImg"] as? String ?? ""
            status.timestamp = statusDict["timestamp"] as? Int ?? 0
            let statusType = statusDict["type"] as? Int ?? 0

            status.type = StatusType(rawValue: statusType)!

            if status.type == .text {
                if let textStatusDict = self.value as? Dictionary<String, AnyObject> {
                    let textStatus = TextStatus()
                    textStatus.statusId = statusId
                    textStatus.text = textStatusDict["text"] as? String ?? ""
                    textStatus.fontName = textStatusDict["fontName"] as? String ?? ""
                    textStatus.backgroundColor = textStatusDict["backgroundColor"] as? String ?? ""
                    status.textStatus = textStatus
                }
            }

        }
        return status
    }
}
