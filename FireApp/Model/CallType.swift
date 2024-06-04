//
//  CallType.swift
//  FireApp
//
//  Created by Devlomi on 9/18/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
enum CallType: Int {
    case VOICE = 1
    case VIDEO = 2
    case CONFERENCE_VOICE = 3
    case CONFERENCE_VIDEO = 4

    var isVideo:Bool{
        return self == CallType.VIDEO || self == CallType.CONFERENCE_VIDEO
    }
    var isGroupCall:Bool{
        return self == CallType.CONFERENCE_VIDEO || self == CallType.CONFERENCE_VOICE

    }

}
