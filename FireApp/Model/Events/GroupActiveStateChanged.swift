//
// Created by Devlomi on 1/1/20.
// Copyright (c) 2020 Devlomi. All rights reserved.
//

import Foundation
class GroupActiveStateChanged{
    var groupId = ""
    var isActive = false

    init(groupId: String, isActive: Bool) {
        self.groupId = groupId
        self.isActive = isActive
    }
}