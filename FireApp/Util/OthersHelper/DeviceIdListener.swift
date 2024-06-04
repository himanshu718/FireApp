//
//  DeviceIdListener.swift
//  FireApp
//
//  Created by Devlomi on 6/15/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase

struct DeviceIdListener {
    static func listenForDeviceIdChanged() -> Observable<Bool> {
        return FireConstants.deviceIdRef.child(FireManager.getUid()).rx.observeEvent(.value).map{snapshot -> Bool in
            
            if let deviceId = snapshot.value as? String{
                //return if deviceId is different
                return deviceId != DeviceId.id
            }else{
                return false
            }
            
            
        }

    }
}
