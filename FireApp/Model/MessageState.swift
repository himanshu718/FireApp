//
// Created by Devlomi on 2019-07-15.
// Copyright (c) 2019 Devlomi. All rights reserved.
//


enum MessageState:Int {
    case PENDING = 0
    case SENT = 1
    case RECEIVED = 2
    case READ = 3
    //used for default(like Date header,GroupEvent,DELETED MESSAGE)
    case NONE = 99

    
}
