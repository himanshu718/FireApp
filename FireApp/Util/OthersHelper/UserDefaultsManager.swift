//
//  UserDefaultsManager.swift
//  FireApp
//
//  Created by Devlomi on 11/7/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
class UserDefaultsManager {

    private static let ringtoneKey = "ringtoneName"
    private static let ringtoneFileNameKey = "ringtoneFileName"
    private static let notificationsOnKeyName = "notificationsOn"

    private static let wallpaperPath = "wallpaperPath"
    private static let saveToCameraRollKey = "saveToCameraRoll"


    private static let photosADKey = "photosADL"
    private static let videoADKey = "videosADL"
    private static let audioADKey = "audioADL"
    private static let documentsADKey = "documentsADL"

    private static let userInfoSavedKey = "userInfoSaved"

    private static let countryCodeKey = "ccode"
    private static let currentPresenceState = "currentPresenceState"



    //Default Values for Auto-Download
    private static let adlImages: AutoDownloadNetworkType = .wifi_cellular
    private static let adlVideos: AutoDownloadNetworkType = .wifi
    private static let adlaudio: AutoDownloadNetworkType = .never
    private static let adlDocuments: AutoDownloadNetworkType = .never





    private static var sharedUserDefaults: UserDefaults {
        return UserDefaults(suiteName: Config.groupName)!
    }

    static func setUserDidLogin(_ bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "didLogin")
    }


    static func userDidLogin() -> Bool {
        UserDefaults.standard.bool(forKey: "didLogin")
    }

    static func setCheckedForBackup(_ bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "checked_for_backup")
    }


    static func isCheckedForBackup() -> Bool {
        UserDefaults.standard.bool(forKey: "checked_for_backup")
    }
    
    
    static func setDeviceIdSaved(_ bool:Bool){
        UserDefaults.standard.set(bool,forKey: "device_id_saved")
    }
    
    static func isDeviceIdSaved() -> Bool{
        UserDefaults.standard.bool(forKey: "device_id_saved")
    }
    
    static func setE2ESaved(_ bool:Bool){
        UserDefaults.standard.set(bool,forKey: "e2e_saved")
    }
    
    static func isE2ESaved() -> Bool{
        UserDefaults.standard.bool(forKey: "e2e_saved")
    }

    static func setRestoreInProgress(_ bool: Bool) {
        UserDefaults.standard.set(bool, forKey: "restore_in_progress")
    }


    static func isRestoreInProgress() -> Bool {
        UserDefaults.standard.bool(forKey: "restore_in_progress") 
    }
    
    
    

    static func getRingtoneName() -> String {
        sharedUserDefaults.string(forKey: ringtoneKey) ?? "Note"
    }

    static func getRingtoneFileName() -> String {
        sharedUserDefaults.string(forKey: ringtoneFileNameKey) ?? "note.m4r"
    }




    static func setRingtione(ringtoneName: String, fileName: String) {
        sharedUserDefaults.setValue(ringtoneName, forKey: ringtoneKey)
        sharedUserDefaults.setValue(fileName, forKey: ringtoneFileNameKey)

        sharedUserDefaults.synchronize()
    }

    static func areNotificationsOn() -> Bool {
        if !isKeyPresentInUserDefaults(key: notificationsOnKeyName, userDefaults: sharedUserDefaults) {
            return true
        }

        return UserDefaults.standard.bool(forKey: notificationsOnKeyName)
    }
    
    static func setPhoneNumber(_ phoneNumber: String) {
        UserDefaults.standard.setValue(phoneNumber, forKey: "phoneNumber")
        UserDefaults.standard.synchronize()
    }

    static func getPhoneNumber() -> String? {
        return UserDefaults.standard.string(forKey: "phoneNumber")
    }

    static func setNotificationsOn(bool: Bool) {
        UserDefaults.standard.setValue(bool, forKey: notificationsOnKeyName)
        UserDefaults.standard.synchronize()
    }

    static func setLastContactsSync(date: Date) {
        UserDefaults.standard.setValue(date, forKey: "lastContactsSync")
        UserDefaults.standard.synchronize()
    }

    static func needsSyncContacts() -> Bool {
        if let storedDate = UserDefaults.standard.object(forKey: "lastContactsSync") as? Date {

            let timeToSync: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours

            let needsSync = Date().timeIntervalSince(storedDate) >= timeToSync

            return needsSync

        }

        return true

    }

    static func setWallpaperPath(path: String) {
        UserDefaults.standard.setValue(path, forKey: wallpaperPath)
        UserDefaults.standard.synchronize()
    }

    static func getWallpaperPath() -> String {
        return UserDefaults.standard.string(forKey: wallpaperPath) ?? ""
    }


    static func setAutoDownloadTypeForMediaType(_ mediaType: MediaType, _ networkType: AutoDownloadNetworkType) {
        let key = mediaKeyByMediaType(mediaType)

        sharedUserDefaults.setValue(networkType.rawValue, forKey: key)
        sharedUserDefaults.synchronize()

    }

    static func getAutoDownloadTypeForMediaType(_ mediaType: MediaType) -> AutoDownloadNetworkType {
        let key = mediaKeyByMediaType(mediaType)

        if !isKeyPresentInUserDefaults(key: key, userDefaults: sharedUserDefaults) {
            return getDefaultNetworkTypeByMediaType(mediaType)
        }

        let networkTypeInt = sharedUserDefaults.integer(forKey: key)

        return AutoDownloadNetworkType(rawValue: networkTypeInt) ?? getDefaultNetworkTypeByMediaType(mediaType)

    }

    static func setSaveToCameraRoll(_ bool: Bool) {
        sharedUserDefaults.setValue(bool, forKey: saveToCameraRollKey)
    }

    static func saveToCameraRoll() -> Bool {
        if !isKeyPresentInUserDefaults(key: saveToCameraRollKey, userDefaults: sharedUserDefaults) {
            return true
        }

        return sharedUserDefaults.value(forKey: saveToCameraRollKey) as? Bool ?? true
    }
    
    
    static func setContactsNeedSync(_ bool: Bool) {
          sharedUserDefaults.setValue(bool, forKey: "contacts_need_sync")
          sharedUserDefaults.synchronize()
      }

    
    static func contactsNeedSync() -> Bool {
          return sharedUserDefaults.value(forKey: "contacts_need_sync") as? Bool ?? false
      }
    
    
    static func setUserInfoSaved(_ bool: Bool) {
         UserDefaults.standard.setValue(bool, forKey: userInfoSavedKey)
    }

    static func isUserInfoSaved() -> Bool {
        return UserDefaults.standard.value(forKey: userInfoSavedKey) as? Bool ?? false
    }

    static func setCountryCode(_ code: String) {
        return sharedUserDefaults.setValue(code, forKey: countryCodeKey)
    }

    static func getCountryCode() -> String {
        return sharedUserDefaults.value(forKey: countryCodeKey) as? String ?? ""
    }

    static func getCurrentPresenceState() -> PresenceStateEnum {
        let stateInt = UserDefaults.standard.value(forKey: currentPresenceState) as? Int ?? 1
        return PresenceStateEnum(rawValue: stateInt)!
    }

    static func setCurrentPresenceState(state: PresenceStateEnum) {
        return UserDefaults.standard.setValue(state.rawValue, forKey: currentPresenceState)
    }

    static func setAgreedToPolicy(bool: Bool) {
        return UserDefaults.standard.setValue(bool, forKey: "agreed_policy")
    }

    static func hasAgreedToPolicy() -> Bool {
        return UserDefaults.standard.value(forKey: "agreed_policy") as? Bool ?? false
    }

    static func setBadge(count: Int) {
        sharedUserDefaults.setValue(count, forKey: "badge_count")
    }
    static func getBadge() -> Int {
        return sharedUserDefaults.value(forKey: "badge_count") as? Int ?? 0
    }

    static func setAppInBackground(bool: Bool) {
        sharedUserDefaults.setValue(bool, forKey: "app_in_background")
    }
    static func isAppInBackground() -> Bool {
        return sharedUserDefaults.value(forKey: "app_in_background") as? Bool ?? false
    }


    static func setAppTerminated(bool: Bool) {
        sharedUserDefaults.setValue(bool, forKey: "app_terminated")
    }
    static func isAppTerminated() -> Bool {
        return sharedUserDefaults.value(forKey: "app_terminated") as? Bool ?? false
    }
    
    
    static func setFetchingUnDeliveredMessages(bool: Bool) {
        sharedUserDefaults.setValue(bool, forKey: "fetchingUndeleiveredMessages")
    }
    static func isFetchingUnDeliveredMessages() -> Bool {
        return sharedUserDefaults.value(forKey: "fetchingUndeleiveredMessages") as? Bool ?? false
    }
    

    static func setLastRequestUnDeliveredMessagesTime(date:Date) {
           sharedUserDefaults.setValue(date, forKey: "lastRequestUnDeliveredMessagesTime")
       }
       static func getLastRequestUnDeliveredMessagesTime() -> Date? {
           return sharedUserDefaults.value(forKey: "lastRequestUnDeliveredMessagesTime") as? Date
       }
       
    
    private static func getDefaultNetworkTypeByMediaType(_ mediaType: MediaType) -> AutoDownloadNetworkType {

        switch mediaType {

        case .photos:
            return adlImages
        case .videos:
            return adlVideos

        case .audio:
            return adlaudio

        case .documents:
            return adlDocuments
        }

    }

    private static func mediaKeyByMediaType(_ mediaType: MediaType) -> String {
        switch mediaType {
        case .photos:
            return photosADKey
        case .videos:
            return videoADKey

        case .audio:
            return audioADKey

        case .documents:
            return documentsADKey
        }

    }

    private static func isKeyPresentInUserDefaults(key: String, userDefaults: UserDefaults) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    static func setTokenSaved(bool: Bool) {
        UserDefaults.standard.setValue(bool, forKey: "isTokenSaved")
    }

    static func isTokenSaved() -> Bool {
        return UserDefaults.standard.value(forKey: "isTokenSaved") as? Bool ?? false
    }
    
    static func setPKTokenSaved(bool: Bool) {
           UserDefaults.standard.setValue(bool, forKey: "isPKTokenSaved")
       }

       static func isPKTokenSaved() -> Bool {
           return UserDefaults.standard.value(forKey: "isPKTokenSaved") as? Bool ?? false
       }
    static func clearAll(){
        let mainBundle = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: mainBundle)
        UserDefaults.standard.synchronize()
        sharedUserDefaults.removePersistentDomain(forName: Config.groupName)
        sharedUserDefaults.synchronize()
    }
}


