//
//  AutoDownloadValues.swift
//  FireApp
//
//  Created by Devlomi on 11/18/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation

enum MediaType: Int {
    case photos = 0
    case audio = 1
    case videos = 2
    case documents = 3

    var string: String {
        var value = ""

        switch self {
            
        case .photos:
            value = Strings.photos
            
        case .audio:
            value = Strings.audio

        case .videos:
            value = Strings.videos

        default:
            value = Strings.documents
        }

        return value
    }
}

enum AutoDownloadNetworkType: Int {
    case never = 0
    case wifi = 1
    case wifi_cellular = 2

    var string: String {
        var value = ""

        switch self {
        case .never:
            value = Strings.never
        case .wifi:
            value = Strings.wifi
        default:
            value = Strings.wifi_cellular
        }

        return value
    }
}
