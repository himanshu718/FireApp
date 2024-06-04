//
//  UserStatuses.swift
//  FireApp
//
//  Created by Devlomi on 10/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import RealmSwift
class UserStatuses: Object {

    
    override static func primaryKey() -> String? {
        return "userId"
    }

    @objc dynamic var userId = ""
    @objc dynamic var lastStatusTimestamp: Int = 0
    @objc dynamic var user: User!
    var statuses = List<Status>()
    @objc dynamic var areAllSeen = false


    public func getMyStatuses() -> Results<Status> {

        return statuses
             .filter("\(DBConstants.TIMESTAMP) >= \(TimeHelper.getTimeBefore24Hours())")
            .sorted(byKeyPath: DBConstants.TIMESTAMP, ascending: false)

    }


    //get only statuses that are not passed 24 hours from local database
    public func getFilteredStatuses() -> Results<Status> {
        

        return statuses
            .filter("\(DBConstants.TIMESTAMP) >= \(TimeHelper.getTimeBefore24Hours())")
            .sorted(byKeyPath: DBConstants.TIMESTAMP, ascending: true)

    }

    override func isEqual(_ object: Any?) -> Bool {
        if let userStatuses = object as? UserStatuses {
            return self.userId == userStatuses.userId
        }
        return false
    }

}
