//
//  Permissions.swift
//  FireApp
//
//  Created by Devlomi on 12/1/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Permission

class Permissions {


    static func isNotificationPermissionsGranted() -> Bool {
        let permission: Permission = .notifications
        return permission.status == .authorized


    }

    static func isContactsPermissionsGranted() -> Bool {
        let permission: Permission = .contacts
        return permission.status == .authorized
    }



    static func requestContactsPermissions(completion: ((_ isAuthorized: Bool) -> Void)?) {
        let permission: Permission = .contacts

        let alert = permission.deniedAlert // or permission.disabledAlert

        alert.title = Strings.permissions_contacts_denied
        alert.message = nil
        alert.cancel = Strings.cancel
        alert.settings = Strings.settings

        permission.deniedAlert = alert

        if permission.status == .authorized {
            completion?(true)
        } else {
            permission.request { status in
                completion?(status == .authorized)
            }
        }
    }

    static func requestMicrophonePermissions(completion: ((_ isAuthorized: Bool) -> Void)?) {
        let permission: Permission = .microphone

        let alert = permission.deniedAlert // or permission.disabledAlert

        alert.title = Strings.permissions_mic_denied
        alert.message = nil
        alert.cancel = Strings.cancel
        alert.settings = Strings.settings

        permission.deniedAlert = alert
        if permission.status == .authorized {
            completion?(true)
        } else {
            permission.request { status in
                completion?(status == .authorized)
            }
        }

    }

    static func requestCameraPermissions(completion: ((_ isAuthorized: Bool) -> Void)?) {
        let permission: Permission = .camera

        let alert = permission.deniedAlert // or permission.disabledAlert

        alert.title = Strings.permissions_camera_denied
        alert.message = nil
        alert.cancel = Strings.cancel
        alert.settings = Strings.settings

        permission.deniedAlert = alert

        if permission.status == .authorized {
            completion?(true)
        }
        else {
            permission.request { status in
                completion?(status == .authorized)
            }
        }
    }

    static func requestPhotosPermissions(completion: ((_ isAuthorized: Bool) -> Void)?) {
        let permission: Permission = .photos

        let alert = permission.deniedAlert // or permission.disabledAlert

        alert.title = Strings.permissions_photos_denied
        alert.message = nil
        alert.cancel = Strings.cancel
        alert.settings = Strings.settings

        permission.deniedAlert = alert
        if permission.status == .authorized {
            completion?(true)
        }
        else {
            permission.request { status in
                completion?(status == .authorized)
            }
        }
    }

    static func requestMicAndVideoPermissions(completion: ((_ isAuthorized: Bool) -> Void)?) {
        let micPermission: Permission = .microphone
        let cameraPermission: Permission = .camera
        if micPermission.status == .authorized && cameraPermission.status == .authorized {
            completion?(true)
        } else {
            requestMicrophonePermissions { (isMicAuthorized) in
                if isMicAuthorized {
                    requestCameraPermissions { (isVideoAuthorized) in
                        completion?(isVideoAuthorized)
                    }
                } else {
                    completion?(false)
                }
            }
        }

    }


}
