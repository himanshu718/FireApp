//
//  UpdateChecker.swift
//  FireApp
//
//  Created by Devlomi on 9/27/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RxSwift

class UpdateChecker {
    static var LOCK = false

    func checkForUpdate() -> Maybe<Bool> {
        if UpdateChecker.LOCK {
            return Maybe<Bool>.empty()
        }
        else {
            UpdateChecker.LOCK = true
        }

        return FireConstants.updateRef.rx.observeSingleEvent(.value).map { snapshot -> UpdateInfo? in
            if snapshot.exists(), let dict = snapshot.value as? Dictionary<String, AnyObject> {
                let latestVersion = dict["latestVersion"] as? Int
                let versionsToUpdate = dict["versionsToUpdate"] as? Int
                let updateCondition = dict["updateCondition"] as? String
                if latestVersion != nil && versionsToUpdate != nil && updateCondition != nil {
                    return UpdateInfo(latestVersion: latestVersion!, versionsToUpdate: versionsToUpdate!, updateCondition: updateCondition!)
                }
            }
            return nil

        }.filter({ $0 != nil }).map { info -> Bool in
            let updateInfo = info!
            let appVersionStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

            let currentAppVersion = Int(appVersionStr!)!



            let latestVersion = updateInfo.latestVersion
            let versionsToUpdate = updateInfo.versionsToUpdate

            if (latestVersion == currentAppVersion) {
                return false
            }

            switch updateInfo.updateCondition {
            case UpdateConditions.ONLY:
                if (versionsToUpdate == currentAppVersion) {
                    return true
                }


            case UpdateConditions.AND_ABOVE:
                if (currentAppVersion >= versionsToUpdate) {
                    return true
                }


            case UpdateConditions.AND_BELOW:
                if (currentAppVersion <= versionsToUpdate) {
                    return true
                }


            case UpdateConditions.NONE:
                return false

            default:
                return false
            }

            return false

        }.do(onNext: { (shouldUpdate) in
            self.saveUpdateMode(shouldUpdate: shouldUpdate)
            UpdateChecker.LOCK = false
        }, onError: { error in
                UpdateChecker.LOCK = false
            }, onCompleted: {
                UpdateChecker.LOCK = false
            })
    }

    private func saveUpdateMode(shouldUpdate: Bool) {
        UserDefaults.standard.set(shouldUpdate, forKey: "should_update")

    }
    
    var needsUpdate:Bool{
        return UserDefaults.standard.value(forKey: "should_update") as? Bool ?? false
    }

}

struct UpdateInfo {
    var latestVersion = -1
    var versionsToUpdate = -1
    var updateCondition = ""

    init(latestVersion: Int, versionsToUpdate: Int, updateCondition: String) {
        self.latestVersion = latestVersion
        self.versionsToUpdate = versionsToUpdate
        self.updateCondition = updateCondition
    }
}

class UpdateConditions: NSObject {
    static let ONLY = "ONLY"
    static let AND_ABOVE = "AND_ABOVE"
    static let AND_BELOW = "AND_BELOW"
    static let NONE = "NONE"
}
