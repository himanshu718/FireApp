//
//  DeviceId.swift
//  FireApp
//
//  Created by Devlomi on 5/16/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
class DeviceId {
    static let id = UIDevice.current.identifierForVendor!.uuidString
}
