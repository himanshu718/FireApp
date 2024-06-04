//
//  Config.swift
//  FireApp
//
//  Created by Devlomi on 12/8/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class Colors {

    static let typingAndRecordingColors = "#0080D4".toColor
    static let notTypingColor = UIColor.darkGray

    static let circularStatusUserColor = "#D81B60".toColor
    static let circularStatusSeenColor = UIColor.lightGray

    static let circularStatusNotSeenColor = UIColor.red

    static let voiceMessageSeenColor = UIColor.blue
    static let voiceMessageNotSeenColor = UIColor.gray

    static let chatsListIconColor = UIColor.gray

    //the default colors for read tags(pending,sent,received) in ChatVC
    static let readTagsDefaultChatViewColor = "#507f48".toColor

    static let readTagsPendingColor = UIColor.gray
    static let readTagsSentColor = UIColor.gray
    static let readTagsReceivedColor = UIColor.gray
    static let readTagsReadColor = "#FF5722".toColor

    static let replySentMsgAuthorTextColor = "#20b66e".toColor
    static let replySentMsgBackgroundColor = "#f7ffef".toColor
    static let sentMsgBgColor = "#b5ff94".toColor


    static let replyReceivedMsgAuthorTextColor = "#0080D4".toColor
    static let replyReceivedMsgBackgroundColor = "#f1f1f1".toColor
    static let receivedMsgBgColor = UIColor.white

    static let highlightMessageColor = UIColor.yellow


}

class TextStatusColors {
    public static let colors = [
        "#FF8A8C",
        "#54C265",
        "#8294CA",
        "#A62C71",
        "#90A841",
        "#C1A03F",
        "#792138",
        "#AE8774",
        "#F0B330",
        "#B6B327",
        "#C69FCC",
        "#8B6990",
        "#26C4DC",
        "#57C9FF",
        "#74676A",
        "#5696FF"
    ]
}

class Config {
    
    // notification type
    // chat : "chat"
    // assignorder : "assign"
    // bid : "bid"
    
    static let Type_Of_Chat = "chat"
    static let Type_Of_AssignOrder = "assign"
    static let Type_Of_Bid = "bid"
    static let Type_Of_Create = "create"
    
//    "${SharedPreferencesManager.getUserName()} Bid for ${order.orderDiscription}"
    
//    "Product ${order.orderDiscription} has been assigned to you by ${SharedPreferencesManager.getCurrentUser().userName}"
    
//    "New Product ${orderName} has been Created by ${SharedPreferencesManager.getCurrentUser().userName} for Lagos."
    
//    static let COLLECTION_BIDS = "bids"
//    static let COLLECTION_ORDERS = "orders"

    static let COLLECTION_BIDS = "bids"+COLLECTION_TEST
    static let COLLECTION_ORDERS = "orders"+COLLECTION_TEST
    static let COLLECTION_TEST = ""
    
    static let maxVideoStatusTime: Double = 30.0
    static let maxVideoTime: Double = 30.0
	
    static let appName = "Gofernet"
    static let bundleName = "com.techwaplimited.gofernet"
    static let groupName = "group.\(bundleName)"
    private static let teamId = "6N99LFGH5Y"

    private static let shareURLScheme = "FireAppShare"
    static let shareUrl = "\(shareURLScheme)://dataUrl=Share"

    static let groupHostLink = ""

    private static let appId = "com.techwaplimited.gofernet"// you can get it from AppStore Connect
    static let appLink = "https://apps.apple.com/app/id\(appId)"
    
    //Encryption Types are: E2E,AES,NONE
    static let encryptionType = "AES"
    
    static let sharedKeychainName = "\(teamId).\(bundleName).\(groupName)"
    
    static let salt = "-2@za#!"
    static let maxSizeAllowed = 50 //50 mb
    static let privacyPolicyLink = ""
    
    static let agoraAppId = ""
    //Ads Disable/Enable
    static let isChatsAdsEnabled = false
    static let isCallsAdsEnabled = false
    static let isStatusAdsEnabled = false

    //Ads Units IDs
    static let mainViewAdsUnitId = "ca-app-pub-3940256099942544~1458002511"//this is a Test Unit ID, replace it with your AdUnitId

    //About
    static let twitter = "https://twitter.com/gofernets"
    static let website = "http://gofernets.com"
    static let email = "gofernets@gmail.com"
    static let accountDelete = "https://gofernets.com/ere/account-deletion/"
    static let facebook = "https://www.facebook.com/gofernets/"
    static let instagram = "https://www.instagram.com/gofernet/"
    static let bankTransfer = "https://gofernets.com/ere/nets"

    public static let MAX_GROUP_USERS_COUNT = 50
    public static let MAX_BROADCAST_USERS_COUNT = 100
    public static let maxGroupCallCount = 1

}



fileprivate extension String {

    var toColor: UIColor {
        var cString: String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
