//
//  CallingState.swift
//  FireApp
//
//  Created by Devlomi on 9/20/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
enum  CallingState {
   case NONE
   case INITIATING
   case CONNECTING
   case CONNECTED
   case FAILED
   case RECONNECTING
   case ANSWERED
   case REJECTED_BY_USER
   case NO_ANSWER
   case ERROR

}
