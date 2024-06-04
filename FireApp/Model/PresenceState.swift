//
//  PresenceState.swift
//  FireApp
//
//  Created by Devlomi on 9/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
struct PresenceState {
    var isOnline = false
    var lastSeen:Double
    
    init(isOnline:Bool,lastSeen:Double) {
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
}

extension PresenceState{
    func getOnlineString() -> String {
        return Strings.online
    }
}
enum PresenceStateEnum:Int{
    case online = 1
    case lastSeen = 2
}
