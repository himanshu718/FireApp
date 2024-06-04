//
//  BadgeManager.swift
//  FireApp
//
//  Created by Devlomi on 2/19/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit

class BadgeManager {

    static func resetBadge(chatId: String, oldBadge: Int) ->Int{
        RealmHelper.getInstance(appRealm).setNotificationCount(chatId: chatId, count: 0)
        let storedBadge = UserDefaultsManager.getBadge()
        let newBadge = storedBadge - oldBadge < 0 ? 0 : storedBadge - oldBadge
        UserDefaultsManager.setBadge(count: newBadge)

        return newBadge
    }

    static func incrementBadgeByOne(chatId: String) -> Int  {
        RealmHelper.getInstance(appRealm).incrementNotificationCount(chatId: chatId)
        let badge = UserDefaultsManager.getBadge()
        let newBadge = badge + 1
        UserDefaultsManager.setBadge(count: newBadge)
        return newBadge
    }
}
