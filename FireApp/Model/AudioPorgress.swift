//
//  AudioPorgress.swift
//  FireApp
//
//  Created by Devlomi on 9/12/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class AudioProgress {
    let currentProgress: TimeInterval
    let duration: TimeInterval
    var playerState:PlayerState

    
    init(currentProgress:TimeInterval,duration:TimeInterval,playerState:PlayerState) {
        self.currentProgress = currentProgress
        self.duration = duration
        self.playerState = playerState
    }
}
