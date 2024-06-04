//
//  AutoDownloadPossibility.swift
//  FireApp
//
//  Created by Devlomi on 1/16/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
class AutoDownloadPossibility {
    static func canAutoDownload(type: MessageType) -> Bool {

        if type == .RECEIVED_VOICE_MESSAGE || type == .RECEIVED_STICKER{
            return true
        }
        
        let autoDownloadValue = UserDefaultsManager.getAutoDownloadTypeForMediaType(getMediaTypeByMessageType(messageType: type))

        if autoDownloadValue == .never {
            return false
        }


        let status = Reach().connectionStatus()


        switch status {
        case .unknown, .offline:
            return false
        case .online(.wwan):
            if autoDownloadValue == .wifi_cellular {
                return true
            }

        case .online(.wiFi):
            if autoDownloadValue == .wifi || autoDownloadValue == .wifi_cellular {
                return true
            }
        }

        return false



    }

    private static func getMediaTypeByMessageType(messageType: MessageType) -> MediaType {
        switch messageType {
        case .RECEIVED_IMAGE:
            return .photos

        case .RECEIVED_AUDIO:
            return .audio

        case .RECEIVED_VIDEO:
            return .videos
        default:
            return .documents
        }
    }

}
