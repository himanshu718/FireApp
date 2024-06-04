//
//  AppDelegate.swift
//  FireApp
//
//  Created by Devlomi on 5/17/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift
import IQKeyboardManagerSwift
import RxSwift
import FirebaseAuth
import FirebaseDatabase
import FirebaseUI
import MapKit
import SwiftEventBus
import FirebaseMessaging
import PushKit
import AgoraRtcKit
import VirgilE3Kit
import CryptoKit
import UserNotifications
import GoogleSignIn


private let fileURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: Config.groupName)!
    .appendingPathComponent("default.realm")

private let config = RealmConfig.getConfig(fileURL: fileURL)
let appRealm = try! Realm(configuration: config)

var arrOfVehicleTypes = ["Car", "Trailer", "Motorcycle", "Truck", "Bicycle", "Ship", "Bus", "Airplane"]

var arrOfStates = ["Abia", "Adamawa", "Akwa Ibom", "Anambra","Abuja", "Bauchi", "Bayelsa", "Benue", "Borno", "Cross River", "Delta", "Ebonyi", "Enugu", "Edo", "Ekiti", "Gombe", "Imo", "Jigawa", "Kaduna", "Kano", "Katsina", "Kebbi", "Kogi", "Kwara", "Lagos", "Nasarawa", "Niger", "Ogun", "Ondo", "Osun", "Oyo", "Plateau", "Rivers", "Sokoto", "Taraba", "Yobe", "Zamfara"]

func changeTimeStampFormate(Time_Stamp : Int64) -> Int64{
    var timestamp = Time_Stamp
    if timestamp > 10000000000{
        timestamp = timestamp / 1000
    }
    return timestamp
}

//var currentOpenChatId = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate{
    
    var currentChatId = ""
    var currentOpenChatId = ""
    
    private var application: UIApplication?
    weak var delegate: ChatCountDelegate?
    private var messages: Results<Message>!
    private var messagesNotificationToken: NotificationToken?
    
    private let disposeBag = DisposeBag()
    private var newNotificationsListeners: NewNotificationsListeners!
    
    private var updateChecker: UpdateChecker!
    private var requestManager:RequestManager!
    private var downloadManager:DownloadManager!
    private var uploadManager:UploadManager!
    private var unProcessedJobs:UnProcessedJobs!
    private var scheduledMessagesManager:ScheduledMessagesManager!
    private var newMessageHandler:NewMessageHandler!
    var window: UIWindow?
    
    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var agoraKit: AgoraRtcEngineKit!
    var isInCall = false
    
    private var disposables = [Disposable]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.application = application
        FirebaseApp.configure()
        UIView.appearance().semanticContentAttribute = .forceLeftToRight
        updateChecker = UpdateChecker()
        
        
        resetApp(application)
        
        initNetworkManagers()
        registerNotifications()
        Messaging.messaging().delegate = self
        configurePushKit()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        initIQKBMgr()
        createAgoraEngine()
        self.window = UIWindow()
        
        goToInitialVC()
        
        //this will be called when the is killed and the user taps on notification
        if FireManager.isLoggedIn, let notificationData = launchOptions?[.remoteNotification] as? NSDictionary, let chatId = notificationData["chatId"] as? String {
            //wait for view to become alive
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SwiftEventBus.post(EventNames.notificationTapped, sender: chatId)
            }
        }
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(15 * 60)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin), name: NSNotification.Name(rawValue: "userDidLogin"), object: nil)
        
        if FireManager.isLoggedIn && UserDefaultsManager.isUserInfoSaved() {
            setPresenceOnDisconnect()
            listenForConnected()
            syncContactsIfNeeded(appRealm: appRealm)
            checkForUpdate()
            
            if !UserDefaultsManager.isDeviceIdSaved(){
                FireManager.saveDeviceId(uid: FireManager.getUid()).subscribe(onCompleted: {
                    UserDefaultsManager.setDeviceIdSaved(true)
                }).disposed(by: disposeBag)
            }
            
//            deleteDeletedUsers()
        }
        
        newNotificationsListeners = NewNotificationsListeners(disposeBag: disposeBag, newMessageHandler: NewMessageHandler(downloadManager: downloadManager, messageDecryptor: MessageDecryptor(decryptionHelper: DecryptionHelper())))
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        if isLoggedIn {
            FCMTokenSaver.saveTokenToFirebase(token: fcmToken).subscribe().disposed(by: disposeBag)
        }
    }
    
    
    // Handle the received remote message
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        // Customize the notification content before displaying it to the user
        var modifiedNotification = remoteMessage.appData
        
        //           if let originalBody = modifiedNotification["body"] as? String {
        //               // Remove some data from the body
        //               let modifiedBody = originalBody.replacingOccurrences(of: "data_to_remove", with: "")
        //               modifiedNotification["body"] = modifiedBody
        //           }
        
        if let originalBody = modifiedNotification["body"] as? String,
           let bodyData = originalBody.data(using: .utf8),
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] {
            
            if let uid = bodyJSON["uid"] as? String {
                print("UID: \(uid)")
            }
            if let data = bodyJSON["data"] as? String {
                print("Data: \(data)")
                modifiedNotification["body"] = data
                
                // Fire the modified notification
                scheduleLocalNotification(with: modifiedNotification)
            }
        }
    }
    
    // Schedule a local notification with the modified content
    func scheduleLocalNotification(with notificationData: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        if let title = notificationData["title"] as? String {
            content.title = title
        }
        if let body = notificationData["body"] as? String {
            content.body = body
        }
        
        // You can customize other notification properties here if needed
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "modified_notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            } else {
                print("Local notification scheduled successfully")
            }
        }
    }
    
    func fetchGroups() {
        GroupManager.fetchGroupsForCurrentUser(userId: FireManager.getUid())
            .subscribe(onNext: { groups in
                print("Group ID:", groups)
            }, onError: { error in
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    func fetchAllUsers(){
        FireConstants.usersRef.observe(.childAdded, with: { snapshot in
            if RealmHelper.getInstance().getUser(uid: snapshot.key) == nil{
                RealmHelper.getInstance().saveObjectToRealm(object: snapshot.toUser())
                print("user \(snapshot.toUser())")
            }
        })
    }
    
    func listenerForNewChat(){
        FireConstants.groupsRef.observe(.childChanged, with: { (snapshot) in
            let Groups = snapshot.value
            self.fetchGroups()
            print("message groups ----- .... ", Groups)
            
            //            snapshot.children.forEach { groupsnapshot in
            //                let groupUser = User()
            //                let group = Group()
            //                print(groupsnapshot)
            //                (groupsnapshot as AnyObject).children.forEach { groupItems in
            //                    print(groupItems)
            //                }
            //            }
        })
    }
    
    let aesCrypto = CryptLib()
    
    func decrypt(fromId:String,message:String,encryptionType:String) -> Single<String> {
        switch encryptionType {
        case EncryptionType.AES:
            return Single.just(aesCrypto.decryptCipherTextRandomIV(withCipherText: message, key: AESKey.key))
            
        case EncryptionType.E2E:
            return EthreeHelper.decryptMessage(fromId: fromId, encryptedMessage: message)
        default:
            return Single.just(message)
        }
    }
    
    func remove(realmURL: URL) {
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management"),
        ]
        for URL in realmURLs {
            try? FileManager.default.removeItem(at: URL)
        }
    }
    
    private func initNetworkManagers(){
        downloadManager = DownloadManager(disposeBag: disposeBag)
        newMessageHandler = NewMessageHandler(downloadManager: downloadManager,messageDecryptor: MessageDecryptor(decryptionHelper: DecryptionHelper()))
        
        uploadManager = UploadManager(disposeBag: disposeBag, messageEncryptor: MessageEncryptor(encryptionHelper: EncryptionHelper()))
        requestManager = RequestManager(disposeBag: disposeBag, downloadManager: downloadManager, uploadManager: uploadManager)
        scheduledMessagesManager = ScheduledMessagesManager(disposeBag: disposeBag)
        unProcessedJobs = UnProcessedJobs(requestManager: requestManager)
        
    }
    
    private func startUpdateVC() {
        unRegisterVCsEvents()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "updateVC")
        self.window?.rootViewController = vc
    }
    
    private func checkForUpdate() {
        let currentNeedsUpdate = updateChecker.needsUpdate
        updateChecker.checkForUpdate().subscribe(onSuccess: { (needsUpdate) in
            if needsUpdate {
                self.startUpdateVC()
            }else{
                if currentNeedsUpdate != needsUpdate{
                    self.goToInitialVC()
                }
                
            }
        }).disposed(by: disposeBag)
    }
    
    
    func setNotificationsListeners() {
        guard FireManager.isLoggedIn else {
            return
        }
        
        let newMessageListener = newNotificationsListeners.attachNewMessagesListeners().subscribe(onNext: { (event) in
            SwiftEventBus.post(EventNames.newMessageReceived, sender: event)
            let message = event.0
            
            let messageType = message.typeEnum
            
            
            if messageType.isMediaType() && AutoDownloadPossibility.canAutoDownload(type: messageType) {
                self.requestManager.request(message: message, callback: nil, appRealm: appRealm)
            }
            
            if self.application?.applicationState == .active {
                if message.chatId != AppDelegate.shared.currentChatId {
                    FireManager.updateMessageState(messageId: message.messageId, chatId: message.chatId, state: .RECEIVED, appRealm: appRealm).subscribe().disposed(by: self.disposeBag)
                }
            }
            
            MessageManager.deleteMessage(messageId: message.messageId).subscribe().disposed(by: self.disposeBag)
        }) { (error) in
            
        }
        
        
        disposables.append(newMessageListener)
        newMessageListener.disposed(by: disposeBag)
        
        let newGroupListener = newNotificationsListeners.attachNewGroupListeners().subscribe(onNext: { (user) in
            GroupManager.subscribeToGroupTopic(groupId: user.uid).subscribe().disposed(by: self.disposeBag)
            
            SwiftEventBus.post(EventNames.newGroupCreated, sender: user)
            MessageManager.deleteNewGroupEvent(groupId: user.uid).subscribe().disposed(by: self.disposeBag)
        })
        
        disposables.append(newGroupListener)
        newGroupListener.disposed(by: disposeBag)
        
        
        
        let deletedMessagesListener = newNotificationsListeners.attachDeletedMessageListener().subscribe(onNext: { (message, user) in
            
            SwiftEventBus.post(EventNames.messageDeleted, sender: (message, user))
            
            MessageManager.deleteDeletedMessage(messageId: message.messageId).subscribe().disposed(by: self.disposeBag)
            
        })
        
        disposables.append(deletedMessagesListener)
        deletedMessagesListener.disposed(by: disposeBag)
        
        
        let listenForScheduledMessageChanges = scheduledMessagesManager.listenForScheduledMessages2().subscribe(onNext: { (messageId, state) in
            self.scheduledMessagesManager.saveMessageAfterSchedulingSucceed(messageId: messageId, state: state)
        })
        
        disposables.append(listenForScheduledMessageChanges)
        listenForScheduledMessageChanges.disposed(by: disposeBag)
        
        let listenForScheduledMessageValueChanges = scheduledMessagesManager.listenForScheduledMessages().subscribe(onNext: { (messageId, state) in
            self.scheduledMessagesManager.saveMessageAfterSchedulingSucceed(messageId: messageId, state: state)
        })
        
        disposables.append(listenForScheduledMessageValueChanges)
        listenForScheduledMessageValueChanges.disposed(by: disposeBag)
        
        let newCallDisposable = newNotificationsListeners.attachNewCall().subscribe()
        disposables.append(newCallDisposable)
        newCallDisposable.disposed(by: disposeBag)
        
        
        if UserDefaultsManager.isUserInfoSaved(){
            let deviceIdChangedDisposable = listenForDeviceIdChanged()
            disposables.append(deviceIdChangedDisposable)
            deviceIdChangedDisposable.disposed(by: disposeBag)
        }
        
    }
    
    func listenForDeviceIdChanged() -> Disposable {
        let deviceIdChangedDisposable = DeviceIdListener.listenForDeviceIdChanged().subscribe {[weak self] (isDeviceIdDifferent) in
            
            
            guard let isDeviceIdDifferent = isDeviceIdDifferent.element, let strongSelf = self else{
                return
            }
            
            if isDeviceIdDifferent {
                //                let loggedOutVC = LoggedOutVC()
                //                strongSelf.window?.rootViewController = loggedOutVC
                //                FireManager.logout()
                //
                //                let content = UNMutableNotificationContent()
                //                content.title = Strings.logged_out
                //                content.body = Strings.logged_out_message
                //                content.sound = UNNotificationSound.default
                //                content.categoryIdentifier = "logged-out"
                //
                //                let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
                //                let request = UNNotificationRequest.init(identifier: "logged-out", content: content, trigger: trigger)
                //
                //                let center = UNUserNotificationCenter.current()
                //                center.add(request)
            }
        }
        
        return deviceIdChangedDisposable
        
    }
    
    func goToInitialVC() {
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if !UserDefaultsManager.hasAgreedToPolicy() {
            let vc = storyboard.instantiateViewController(withIdentifier: "mainVc")
            self.window?.rootViewController = vc
        } else if !FireManager.isLoggedIn {
            let vc = LoginVC()
            self.window?.rootViewController = vc
        } else {
            if updateChecker.needsUpdate {
                // Present update view controller
                startUpdateVC()
            } else if Config.encryptionType == EncryptionType.E2E && !UserDefaultsManager.isE2ESaved() {
                // Present SaveE2EVC if encryption is enabled and not saved
                let vc = SaveE2EVC()
                self.window?.rootViewController = vc
            } else if !UserDefaultsManager.isCheckedForBackup()
                        && !UserDefaultsManager.isUserInfoSaved() {
                // Present RestoreBackupNavVC if backup not checked or restore in progress
                let restoreBackupVC = storyboard.instantiateViewController(withIdentifier: "RestoreBackupNavVC")
                self.window?.rootViewController = restoreBackupVC
            } else if !UserDefaultsManager.isUserInfoSaved() {
                // Present SetupUserNavVC if user info not saved
                let setupUserVc = storyboard.instantiateViewController(withIdentifier: "SetupUserNavVC")
                self.window?.rootViewController = setupUserVc
            } else {
                // Present RootNavController as the default root view controller
                let rootNavController = storyboard.instantiateViewController(withIdentifier: "RootNavController")
                self.window?.rootViewController = rootNavController
            }
        }
        
        self.window?.makeKeyAndVisible()
    }

    
    func syncContactsIfNeeded(appRealm: Realm) {
        
        if Permissions.isContactsPermissionsGranted() && UserDefaultsManager.needsSyncContacts() && UserDefaultsManager.isUserInfoSaved() {
            ContactsUtil.syncContacts(appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
    }
    
    func setPresenceOnDisconnect() {
        if FireManager.isLoggedIn {
            FireConstants.presenceRef.child(FireManager.getUid()).onDisconnectSetValue(ServerValue.timestamp())
        }
    }
    
    func listenForConnected() {
        if FireManager.isLoggedIn {
            
            Database.database().reference(withPath: ".info/connected").rx.observeEvent(.value).flatMap { snapshot -> Observable<DatabaseReference> in
                if let connected = snapshot.value as? Bool {
                    if connected {
                        self.unProcessedJobs.process(disposeBag: self.disposeBag)
                        return FireManager.setOnlineStatus()
                    } else {
                        return FireManager.setLastSeen()
                        
                    }
                } else {
                    return Observable.empty()
                }
            }.subscribe().disposed(by: disposeBag)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
        
        UserDefaultsManager.setAppTerminated(bool: true)
        UserDefaultsManager.setAppInBackground(bool: true)
        messages = nil
        messagesNotificationToken = nil
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if !FireManager.isLoggedIn {
            completionHandler(.noData)
            return
        }
        if application.applicationState == .background {
            	
            if UserDefaultsManager.getCurrentPresenceState() == .online {
                FireManager.setLastSeen().subscribe(onError: { (error) in
                    completionHandler(.failed)
                }, onCompleted: {
                    completionHandler(.newData)
                }).disposed(by: disposeBag)
            } else {
                completionHandler(.noData)
            }
        } else {
            completionHandler(.noData)
        }
    }
    
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//            // Customize the presentation of the notification when the app is in the foreground, if needed
//            completionHandler([.alert, .sound, .badge])
//        }
        
        // Handle tap on notification
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//            // Handle tap on the notification, if needed
//            completionHandler()
//        }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        
        if FireManager.isLoggedIn {
            FireManager.setLastSeen().subscribe().disposed(by: disposeBag)
            for disposable in disposables {
                disposable.dispose()
            }
            disposables.removeAll()
        }
        
        
        UserDefaultsManager.setAppInBackground(bool: true)
        SwiftEventBus.post(EventNames.appStateChangedEvent, sender: UIApplication.State.background)
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // If there is one established call, show the callView of the current call when
        // the App is brought to foreground. This is mainly to handle the UI transition
        // when clicking the App icon on the lockscreen CallKit UI.
        guard FireManager.isLoggedIn else {
            return
        }
        
        if isInCall {
            
            if var topController = self.window?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                
                
                // When entering the application via the App button on the CallKit lockscreen,
                // and unlocking the device by PIN code/Touch ID, applicationWillEnterForeground:
                // will be invoked twice, and "top" will be CallViewController already after
                // the first invocation.
                if !(topController is CallingVC) {
                    topController.performSegue(withIdentifier: "toCallingVC", sender: nil)
                }
            }
        }
        
    }
    
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
        //fix for textView when it gets pushed down while closing the app and re-open it
        IQKeyboardManager.shared.reloadLayoutIfNeeded()
        SwiftEventBus.post(EventNames.appStateChangedEvent, sender: UIApplication.State.active)
        if FireManager.isLoggedIn {
            
            RealmHelper.getInstance(appRealm).deleteExpiredStatuses()
            
            
            FireManager.setOnlineStatus().subscribe().disposed(by: disposeBag)
            
            if isLoggedIn{
                
                unProcessedJobs.process(disposeBag: disposeBag)
                
                setNotificationsListeners()
                
            }
            
            
        }
        UserDefaultsManager.setAppInBackground(bool: false)
        
        UserDefaultsManager.setAppTerminated(bool: false)
        
        
        
        
        
        
    }
    
    private var isLoggedIn:Bool{
        //if e2e is not enabled, it will be true by default.
        let isE2e = Config.encryptionType == EncryptionType.E2E
        
        let isE2eSaved = isE2e ? UserDefaultsManager.isE2ESaved() : true
        
        return FireManager.isLoggedIn && isE2eSaved
    }
    
    @objc func userDidLogin() {
        
        
        registerNotifications()
        //sync contacts for the first time
        if FireManager.isLoggedIn && UserDefaultsManager.isUserInfoSaved() {
            if Permissions.isContactsPermissionsGranted() && RealmHelper.getInstance(appRealm).getUsers().isEmpty {
                ContactsUtil.syncContacts(appRealm: appRealm).subscribe().disposed(by: disposeBag)
            }
            
            let deviceIdChangedDisposable = listenForDeviceIdChanged()
            disposables.append(deviceIdChangedDisposable)
            deviceIdChangedDisposable.disposed(by: disposeBag)
            
            if disposables.isEmpty && isLoggedIn {
                setNotificationsListeners()
            }
        }
        
        
        if isLoggedIn{
            FCMTokenSaver.saveTokenToFirebase(token: nil).subscribe().disposed(by: disposeBag)
        }
        
        checkForUpdate()
        if !UserDefaultsManager.isPKTokenSaved() && isLoggedIn{
            configurePushKit()
        }
        
        UserDefaultsManager.setUserDidLogin(true)
    }
    
    private func registerNotifications() {
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in
                
                center.delegate = self
            }
            
            
        )
        
        application?.registerForRemoteNotifications()
    }
    fileprivate func resetApp(_ application: UIApplication) {
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: "hasRunBefore") {
            // Remove Keychain items here
            
            do {
                application.applicationIconBadgeNumber = 0
                //if the user was logged in before then sign him out
                try FireManager.auth().signOut()
                
            } catch let error {
                
            }
            // Update the flag indicator
            userDefaults.set(true, forKey: "hasRunBefore")
        }
    }
    
    fileprivate func initIQKBMgr() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.touchResignedGestureIgnoreClasses.append(UnResignableKBView.self)
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier, let chatId = response.notification.request.content.userInfo["chatId"] as? String {
            SwiftEventBus.post(EventNames.notificationTapped, sender: chatId)
        }
        completionHandler()
    }
    
    func configurePushKit() {
        // Register for VoIP notifications
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    fileprivate func handleGroupEvent(userInfo: [AnyHashable: Any]) {
        if let groupId = userInfo["groupId"] as? String, let eventId = userInfo["eventId"] as? String, let contextStart = userInfo["contextStart"] as? String, let eventTypeStr = userInfo["eventType"] as? String, let contextEnd = userInfo["contextEnd"] as? String {
            
            let eventTypeInt = Int(eventTypeStr) ?? 0
            let eventType = GroupEventType(rawValue: eventTypeInt) ?? .UNKNOWN
            //if this event was by the admin himself  OR if the event already exists do nothing
            if contextStart != FireManager.number! && RealmHelper.getInstance(appRealm).getMessage(messageId: eventId) == nil {
                let groupEvent = GroupEvent(contextStart: contextStart, type: eventType, contextEnd: contextEnd)
                
                let pendingGroupJob = PendingGroupJob(groupId: groupId, type: eventType, event: groupEvent)
                RealmHelper.getInstance(appRealm).saveObjectToRealm(object: pendingGroupJob)
                GroupManager.updateGroup(groupId: groupId, groupEvent: groupEvent).subscribe(onCompleted: {
                    RealmHelper.getInstance(appRealm).deletePendingGroupJob(groupId: groupId)
                    
                }).disposed(by: disposeBag)
            }
        }
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //
        
        print("userinfo", userInfo)
        
        //        push.application(application, didReceiveRemoteNotification: userInfo)
        if let event = userInfo["event"] as? String {
            if event == "group_event" {
                handleGroupEvent(userInfo: userInfo)
            } else {
                completionHandler(UIBackgroundFetchResult.noData)
            }
            
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("notification... error", error)
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
        print("\(token)")
        //        push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        
        // With swizzling disabled you must set the APNs token here.
        //         Messaging.messaging().apnsToken = deviceToken
    }
    
    func getUser(uid: String, phone: String) -> User {
        if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid) {
            return user
        }
        
        //save temp user data while fetching all data later
        let user = User()
        user.phone = phone
        user.uid = uid
        user.userName = phone
        user.isStoredInContacts = false
        
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user)
        
        return user
    }
    
    func createAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: Config.agoraAppId, delegate: nil)
    }
    private func deleteDeletedUsers(){
        ContactsUtil.deleteDeletedUsers().subscribe().disposed(by: disposeBag)
    }
    
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            
            guard let url = userActivity.webpageURL else { return false }
            guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else { return false }
            guard let host = components.host else { return false }
            
            if let pathComponents = components.path {
                
                let groupLink = pathComponents.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "/", with: "")
                
                guard groupLink.isNotEmpty else { return false }
                
                SwiftEventBus.post(EventNames.groupLinkTapped, sender: groupLink)
                
                return true
            }
        }
        return false
    }
    
    
    fileprivate func unRegisterVCsEvents() {
        if let viewControllers = window?.rootViewController?.children {
            for viewController in viewControllers {
                if let baseVc = viewController as? Base {
                    //remove events to prevent duplicate unRead counts
                    baseVc.unRegisterEvents()
                }
                
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        if url.absoluteString == Config.shareUrl {
            // Handle your custom URL logic here
            unRegisterVCsEvents()
            // Reset chatId
            currentChatId = ""
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let shareNavVC = storyboard.instantiateViewController(withIdentifier: "shareNavVC")
            self.window?.rootViewController = shareNavVC
            self.window?.makeKeyAndVisible()
            
            return true
        } else {
            // Handle other URL schemes
            return GIDSignIn.sharedInstance.handle(url)
        }
        
    }
}




extension AppDelegate: PKPushRegistryDelegate {
    // Handle updated push credentials
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        
        
        if !isLoggedIn {
            return
        }
        
        FCMTokenSaver.savePKTokenToFirebase(token: deviceToken).subscribe().disposed(by: disposeBag)
    }
    
    fileprivate func setMissedCall(_ fireCall: FireCall, _ groupName: String, _ user: User, _ callId: String) {
        RealmHelper.getInstance(appRealm).setCallDirection(callId: fireCall.callId, callDirection: .MISSED)
        
        
        let body = groupName.isEmpty ? user.properUserName : groupName
        let content = UNMutableNotificationContent()
        content.title = Strings.missed_call
        content.body = body
        
        let request = UNNotificationRequest(identifier: callId, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if let error = error { }
        })
        
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        
        let data = payload.dictionaryPayload
        guard let callId = data["callId"] as? String else {
            return
        }
        
        
        
        let fromId = data["callerId"] as? String ?? ""
        
        let typeStr = Int((data["callType"]as? String ?? "1"))
        
        let type = CallType(rawValue: typeStr ?? CallType.VOICE.rawValue)!
        
        
        let groupId = data["groupId"] as? String ?? ""
        
        let isGroupCall = type.isGroupCall
        
        
        
        let channel = data["channel"] as! String
        
        let groupName = data["groupName"] as? String ?? ""
        
        let timestamp = Int(data["timestamp"] as? String ?? Date().currentTimeMillisStr())!
        
        let phoneNumber = data["phoneNumber"] as? String ?? ""
        
        let isVideo = type.isVideo
        
        let uid = isGroupCall ? groupId : fromId
        
        
        var user: User
        
        let storedUser = RealmHelper.getInstance(appRealm).getUser(uid: uid)
        
        
        if (storedUser == nil) {
            //make dummy user temporarily
            user = User()
            if isGroupCall {
                user.uid = groupId
                user.isGroupBool = true
                user.userName = groupName
                let group = Group()
                group.groupId = groupId
                group.isActive = true
                
                
                let currentUser = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
                
                group.users.append(currentUser!)
                user.group = group
            } else {
                user.uid = uid
                user.phone = phoneNumber
            }
        } else {
            user = storedUser!
        }
        
        let callUUID = UUID()
        
        let fireCall = FireCall(callId: callId, callUUID: callUUID.uuidString, user: user, callType: type, callDirection: .INCOMING, channel: channel, timestamp: timestamp, duration: 0, phoneNumber: phoneNumber, isVideo: isVideo)
        
        ProviderDelegate.sharedInstance.reportIncomingCall(fireCall)
        
        if TimeHelper.isTimePassedBySeconds(biggerTime: Double(Date().currentTimeMillis()), smallerTime: Double(timestamp), seconds: FireCallsManager.CALL_TIEMOUT_SECONDS) {
            
            ProviderDelegate.sharedInstance.reportMissedCall(uuid: callUUID, date: Date(timeIntervalSince1970: TimeInterval(timestamp)), reason: .answeredElsewhere)
            
            setMissedCall(fireCall, groupName, user, callId)
            
        } else {
            if !isInCall {
                FireCallsManager().listenForEndingCall(callId: fireCall.callId, otherUid: uid, isIncoming: true).subscribe(onNext: { (snapshot) in
                    if snapshot.exists() {
                        
                        if let call = RealmHelper.getInstance(appRealm).getFireCall(callId: callId), call.callDirection != .ANSWERED {
                            self.setMissedCall(fireCall, groupName, user, callId)
                            ProviderDelegate.sharedInstance.reportMissedCall(uuid: callUUID, date: Date(timeIntervalSince1970: TimeInterval(timestamp)), reason: .unanswered)
                        }
                        
                    }
                }).disposed(by: disposeBag)
                
            } else {
                ProviderDelegate.sharedInstance.reportMissedCall(uuid: callUUID, date: Date(timeIntervalSince1970: TimeInterval(timestamp)), reason: .answeredElsewhere)
                
                setMissedCall(fireCall, groupName, user, callId)
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        
    }
}

//push notifications

func pushNotificationCreateMessage(groupId: String, userName: String, message: String) {
    
    FireConstants.groupsRef.child(groupId).child("users").observeSingleEvent(of: .value) { (snapshot) in
        if let data = snapshot.value as? [String: Any]{
            for(key, _) in  data{
                if FireManager.getUid() != key{
                    print("USERS ID====== \(key)")
                    FireConstants.usersRef.child(key).child("notificationTokens").observeSingleEvent(of: .value) { (tokenSnapshot) in
                        if let tokenData = tokenSnapshot.value as? [String: Any]{
                            for (token, _)  in tokenData {
                                sendPushNotification(to: token, userName: userName, message: message, userId: groupId, type: "chat")
                            }
                        }
                    }
                }
            }
        }
    }
}


func pushNotificationCreateUserId(userId: String, userName: String, message: String, type: String) {
    FireConstants.usersRef.child(userId).child("notificationTokens").observeSingleEvent(of: .value, with: { (snapshot) in
        if let data = snapshot.value as? [String: Any] {
            for (key, _) in data {
                sendPushNotification(to: key, userName: userName, message: message, userId: userId, type: type)
            }
        }
    }) { (error) in
        print("Database Error: \(error.localizedDescription)")
    }
}

func sendPushNotification(to token: String, userName: String, message: String, userId: String, type: String) {
    let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
    
    let headers: [String: String] = [
        "Content-Type": "application/json",
        "Authorization": "key=AAAAqK_5R_o:APA91bGRAsr4JPLwanuh5-mYliqDIWMmPVPAU7O_vr0zL3_Rpeuk7L5nqYXff57ZdBrMRpwPzBmwEhrIuaS1-zM1n4yXqLtSXq-qSETVafNEEEnx3wQ88GAURet1wMgZQk3LW-fGNIO2" // Replace with your server key from the Firebase Console
    ]
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.allHTTPHeaderFields = headers
    
    //    request.httpBody = jsonData
    let jsonMessage = [
        "uid": FireManager.getUid(),
        "data": message,
        "groupId": userId,
        "type":type
    ]
    let notification = [
        "to": token,
        "notification": [
            "title": userName,
            "body": message,
            "sound": "coin.wav",
            "data": jsonMessage
        ],
        "data": [
            "userId": userId,
            "type": type
        ]
    ] as [String : Any]
    
    let jsonData = try! JSONSerialization.data(withJSONObject: notification)
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending FCM request: \(error.localizedDescription)")
            return
        }
        
        if let data = data {
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            print("FCM Response: \(responseJSON ?? "")")
        }
    }
    
    task.resume()
}
//func sendPushNotification(to token: String, title: String, body: String, data : [String: Any]) {
//
//        let urlString = "https://fcm.googleapis.com/fcm/send"
//        let url = URL(string: urlString)!
//
//        let headers: [String: String] = [
//            "Content-Type": "application/json",
//            "Authorization": "key=YOUR_SERVER_KEY" // Replace with your server key from the Firebase Console
//        ]
//
//        let notification: [String: Any] = [
//            "title": title,
//            "body": body
//        ]
//
//        let data: [String: Any] = [
//            "to": token,
//            "notification": notification,
//            "data": data,
//            "priority": "high"
//        ]
//
//        let jsonData = try? JSONSerialization.data(withJSONObject: data)
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.allHTTPHeaderFields = headers
//        request.httpBody = jsonData
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error sending notification:", error.localizedDescription)
//                return
//            }
//
//            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
//                print("Notification sent successfully")
//            } else {
//                print("Error sending notification. Status code:", (response as? HTTPURLResponse)?.statusCode ?? 0)
//            }
//        }
//
//        task.resume()
//    }

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received JSON data: \(userInfo)")
        if let id = userInfo["gcm.message_id"] as? String,
           let bodyDict = userInfo["aps"] as? [String: Any],
           let alertString = bodyDict["alert"] as? [String: Any],
           let bodyString = alertString["body"] as? String,
           let titlrString = alertString["title"] as? String,
           let bodyData = bodyString.data(using: .utf8),
           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] {
            
            if let uid = bodyJSON["uid"] as? String {
                print("UID: \(uid)")
            }
            if let data = bodyJSON["data"] as? String {
                print("Data: \(data)")
                let customNotification = UNMutableNotificationContent()
                customNotification.title = titlrString
                customNotification.body = data
//                scheduleNotificationButtonTapped(title: titlrString, body: data)
                let request = UNNotificationRequest(identifier: id, content: customNotification, trigger: nil)
                UNUserNotificationCenter.current().add(request) { (error) in
                    if let error = error {
                        print("Error presenting custom notification: \(error)")
                    }
                }
            }
            
            if let groupId = bodyJSON["groupId"] as? String {
                print("Group ID: \(groupId)")
            }
            if let type = bodyJSON["type"] as? String {
                print("Type: \(type)")
            }
        } else {
            print("No valid JSON data found for key 'body'")
        }
        
        let options: UNNotificationPresentationOptions = [.alert, .badge, .sound]
        
        completionHandler(options)
    }
    
    func scheduleNotificationButtonTapped(title:String,body:String) {
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default
            
            // Create a trigger for the notification (e.g., time-based trigger)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            // Create a notification request with the content and trigger
            let request = UNNotificationRequest(identifier: "notification-1", content: content, trigger: nil)
            
            // Add the request to the notification center
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                    print("Notification scheduled successfully")
                }
            }
        }
}
//
//    //    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//    //        let userInfo = notification.request.content.userInfo
//    //        print("Received JSON data: \(userInfo)")
//    //        if let bodyDict = userInfo["aps"] as? [String: Any],
//    //           let alertString = bodyDict["alert"] as? [String: Any],
//    //           let bodyString = alertString["body"] as? String,
//    //           let titleString = alertString["title"] as? String,
//    //           let bodyData = bodyString.data(using: .utf8),
//    //           let bodyJSON = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] {
//    //
//    //            if let uid = bodyJSON["uid"] as? String {
//    //                print("UID: \(uid)")
//    //            }
//    //            if let data = bodyJSON["data"] as? String {
//    //                print("Data: \(data)")
//    //                let customNotification = UNMutableNotificationContent()
//    //                customNotification.title = titleString
//    //                customNotification.body = data
//    ////                notification["data"] = data
//    //                // Check if a notification with identifier "customNotification" already exists
//    //                let existingRequests = UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
//    //                    var notificationExists = false
//    //                    for request in requests {
//    //                            if request.identifier == "customNotification" {
//    //                                notificationExists = true
//    //                                break
//    //                            }
//    //                        }
//    //
//    //                        if notificationExists {
//    //                            let request = UNNotificationRequest(identifier: "customNotification", content: customNotification,
//    //                                                                trigger: nil)
//    //                            UNUserNotificationCenter.current().add(request) { (error) in
//    //                                if let error = error {
//    //                                    print("Error updating custom notification: \(error)")
//    //                                }
//    //                            }
//    //                        } else {
//    //                            // Handle the case when the notification doesn't exist
//    //                                // Schedule a new notification
//    //                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//    //                                let request = UNNotificationRequest(identifier: "customNotification", content: customNotification,
//    //                                                                    trigger: trigger)
//    //                                UNUserNotificationCenter.current().add(request) { (error) in
//    //                                    if let error = error {
//    //                                        print("Error presenting custom notification: \(error)")
//    //                                    }
//    //                                }
//    //                        }
//    //                }
//    //            }
//    //
//    //            if let groupId = bodyJSON["groupId"] as? String {
//    //                print("Group ID: \(groupId)")
//    //            }
//    //            if let type = bodyJSON["type"] as? String {
//    //                print("Type: \(type)")
//    //            }
//    //        } else {
//    //            print("No valid JSON data found for key 'body'")
//    //        }
//    //        let options: UNNotificationPresentationOptions = [.alert, .badge, .sound]
//    //        completionHandler(options)
//    //    }
//}

