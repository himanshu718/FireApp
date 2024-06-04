//
//  RealmConfig.swift
//  FireApp
//
//  Created by Devlomi on 9/18/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import RealmSwift
class RealmConfig {
    private static let schemaVersion: UInt64 = 4
    
    static func getConfig(fileURL: URL, objectTypes: [Object.Type]? = nil) -> Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL!.deleteLastPathComponent()
        config.fileURL!.appendPathComponent("gofernets")
        config.fileURL!.appendPathExtension("realm")
        return config
    }

}
