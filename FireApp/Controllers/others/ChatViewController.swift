//
//  ViewController.swift
//  FireApp
//
//  Created by Devlomi on 5/18/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import Realm
import FirebaseDatabase
import UITextView_Placeholder
import BubbleTransition
import Photos
import Hero
import iRecordView
import AVFoundation
import JFContactsPicker
import ContactsUI
import AddressBook
import LocationPicker
import GrowingTextView
import ContextMenu
import SwiftEventBus
import RxSwift
import IQKeyboardManagerSwift
import QuickLook
import KBStickerView

protocol ChatVCDelegate {
    func segueToChatVC(user: User)
}

class ChatViewController: BaseVC, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    
    var isLoadedd = false
    var isHomePush = false
    var currentFilePath: String = ""
    
    var searchIndex = 0
    
    var recorder: AudioRecorder!
    
    var realmHelper: RealmHelper!
    
    var requestManager:RequestManager!
    var downloadManager:DownloadManager!
    var uploadManager:UploadManager!
    var scheduledMessagesManager:ScheduledMessagesManager!
    
    var user: User!
    
    var senderUser: User!
    
    var audioPlayer: AudioPlayer!
    
    var chat: Chat?
    
    var progressDict = [String: Float]()
    var audioProgressDict = [String: AudioProgress]()
    
    let transition = BubbleTransition()
    let interactiveTransition = BubbleInteractiveTransition()
    
    var userNameLbl: UILabel!
    var typingStateLbl: UILabel!
    var availableStateLbl: UILabel!
    var userImgView: UIImageView!
    
    private let schedulingModeViewDefaultHeight = 60
    
    var isInSchedulingMode = false{
        didSet{
            if isInSchedulingMode{
                schedulingModeView.isHidden = false
                schedulingModeViewHeightConstraint.constant = 60
            }else{
                schedulingModeViewHeightConstraint.constant = 0
            }
            
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
                self.schedulingModeView.isHidden = !self.isInSchedulingMode
            }
        }
    }
    
    private var schedulingDate:Date = Date()
    
    var unReadCount = 0
    var previousMessageIdForScroll = ""
    
    var currentReceiverTypingState: TypingState = .NOT_TYPING
    var currentReceiverOnlineState: PresenceState = PresenceState(isOnline: false, lastSeen: 0)
    
    var delegate: ChatVCDelegate?
    
    
    var callingButtonsNavigation: UIBarButtonItem!
    
    var currentQuotedMessage: Message? = nil
    
    var updatePresenceObservable: Disposable?
    
    var isInSelectMode = false {
        
        didSet {
            tblView.allowsSelection = isInSelectMode
            tblView.allowsMultipleSelection = isInSelectMode
            toolbar.isHidden = !isInSelectMode
            typingViewContainer.isHidden = isInSelectMode
            
            recordButton.isHidden = isInSelectMode
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            
            if self.isInSelectMode {
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelActionMode))
                
                toolbarBottomConstraint.constant = 0
                backgroundView.bottomAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
                navigationItem.hidesBackButton = true
                
            } else {
                selectedItems.removeAll()
                navigationItem.hidesBackButton = false
                navigationItem.rightBarButtonItem = callingButtonsNavigation
                backgroundView.bottomAnchor.constraint(equalTo: typingViewContainer.topAnchor, constant: -16).isActive = true
                toolbarBottomConstraint.constant = 2000
            }
            
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            
            
            for cell in tblView.visibleCells {
                if let cell = cell as? BaseCell {
                    cell.isInSelectMode = isInSelectMode
                    if !isInSelectMode {
                        cell.isMessageSelected = false
                    }
                }
            }
        }
    }
    
    var contextSelectedItemType: ContextItemType = .forward {
        didSet {
            if contextSelectedItemType == .delete {
                
                leftButtonToolbar = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(toolbarTrashDidClick))
                
                toolbar.items?[0] = leftButtonToolbar
                
                rightButtonToolbar.hide()
                
            } else if contextSelectedItemType == .forward {
                leftButtonToolbar = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(toolbarForwardDidClick))
                
                toolbar.items?[0] = leftButtonToolbar
                
                rightButtonToolbar.show()
            }
        }
    }
    
    //selected items when user enter selection mode
    var selectedItems = [Message]()
    
    var notificationToken: NotificationToken? = nil
    
    var observableListNotificationToken: NotificationToken? = nil
    
    var observableGroupStateToken: NotificationToken? = nil
    
    var messages: Results<Message>!
    var observableList: Results<Message>!
    
    var proximitySensorHelper: ProximitySensorHelper!
    
    var viewHasAppeared = false
    
    var leftButtonToolbar: UIBarButtonItem!
    var toolbarTitle: ToolBarTitleItem!
    var rightButtonToolbar: UIBarButtonItem!
    
    var searchBar: UISearchBar!
    //search items
    var arrowsToolbar: UIToolbar!
    var upArrowItem: UIBarButtonItem!
    var downArrowItem: UIBarButtonItem!
    //current found search results
    var searchResults: Results<Message>!
    
    var isInSearchMode = false
    
    //MARK: - Outlets
    
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var textView: GrowingTextView!
    @IBOutlet weak var btnCamera: UIButton!
    @IBOutlet weak var btnSticker: UIButton!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var backgroundView: UIImageView!
    
    //Replay Layout Views
    @IBOutlet weak var replyLayout: UIView!
    @IBOutlet weak var replyUserName: UILabel!
    @IBOutlet weak var replyIcon: UIImageView!
    @IBOutlet weak var replyDescTitle: UILabel!
    @IBOutlet weak var replyThumb: UIImageView!
    @IBOutlet weak var replyCancel: UIButton!
    
    @IBOutlet weak var typingViewContainer: UIView!
    @IBOutlet weak var typingViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var recordButtonBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var recordViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyLayoutBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var schedulingModeViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toolbar: UIToolbar!
    private var kbStickerView:KBStickerView!
    @IBOutlet weak var recordButton: SendButton!
    @IBOutlet weak var recordView: RecordView!
    
    @IBOutlet weak var scrollDownView: UIView!
    @IBOutlet weak var unreadMessagesLbl: UILabel!
    @IBOutlet weak var cantReplyView: UIView!
    @IBOutlet weak var cantReplyLbl: UILabel!
    
    @IBOutlet weak var schedulingModeView: UIView!
    @IBOutlet weak var cancelSchedulingModeBtn: UIButton!
    
    //MARK: - Button Actions
    @IBAction func btnSend(_ sender: Any) {
        sendMessage(textMessage: textView!.text!)
        
        cancelReplyDidClick()
    }
    
//    @IBAction func btnAdd(_ sender: Any) {
//        let style:UIAlertController.Style = UIDevice.isPhone ? .actionSheet : .alert
//        let alert = ChooseActionAlertController(title: nil, message: nil, preferredStyle: style)
//        alert.setup()
//        alert.delegate = self
//
//        self.present(alert, animated: true) {
//            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
//            alert.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
//        }
//    }
    
    @objc private func dismissAlertController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancelActionMode() {
        isInSelectMode = false
    }
    
    private var isKeyboardType = true {
        didSet {
            if isKeyboardType {
                btnSticker.setImage(UIImage(named: "ic_sticker_small"), for: .normal)
                textView.inputView = nil
                textView.reloadInputViews()
            } else {
                btnSticker.setImage(UIImage(named: "ic_keyboard"), for: .normal)
                textView.inputView = kbStickerView
                textView.reloadInputViews()
            }
        }
    }
    
    @objc private func btnStickerTapped(){
        isKeyboardType = !isKeyboardType
        if !isKeyboardType{
            textView.becomeFirstResponder()
        }
    }
    
    private var keyboardHeight:CGFloat = 0
    
    //schedule timer to update lastSeen time every two minutes
    private func scheduleTimer() {
        if user.isGroupBool || user.isBroadcastBool {
            return
        }
        
        updatePresenceObservable?.dispose()
        
        let intervalTime = RxTimeInterval.seconds(2 * 60)
        
        updatePresenceObservable = Observable<Int>.interval(intervalTime, scheduler: MainScheduler.instance).subscribe(onNext: { (time) in
            
            if !self.currentReceiverOnlineState.isOnline {
                self.setCurrentPresenceState(state: self.currentReceiverOnlineState)
                self.updateToolbarLabelsVisibility(hideOnlineStatToolbar: false)
            }
            
        })
        
        updatePresenceObservable?.disposed(by: disposeBag)
    }
    
    //MARK: - ViewCycle Methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
        
        UIView.animate(withDuration: 0.2) {
            self.navigationController?.isNavigationBarHidden = false
        }
        
        if !user.isBroadcastBool {
            FireManager.checkAndDownloadUserThumb(user: user, appRealm: appRealm).subscribe(onNext: { (thumbImg) in
                self.userImgView.image = thumbImg.toUIImage()
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        }
        
        scheduleTimer()
        
        setMessagesAsSeenLocally()
        
        addKeyboardChangeObserver()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !viewHasAppeared {
            guard messages.count > 0 else {
                return
            }
            
            //scroll to bottom once view loaded
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tblView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            tblView.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
      
        if self.isBeingDismissed
        {
            print("click back button------")
        }
        AppDelegate.shared.currentChatId = ""
        AppDelegate.shared.currentOpenChatId = ""
        NewMessageHandler.customChatId = ""
        
        removeTokens()
        SwiftEventBus.unregister(self)
        //hide kb
        textView.endEditing(true)
        
        if self.isMovingFromParent {
            if isHomePush{
                for vc in self.navigationController!.viewControllers {
                    if #available(iOS 13.0, *) {
                        if ((vc as? VendorTabPageViewController) != nil) || ((vc as? OrderDetailViewController) != nil)  {
                            self.navigationController?.popToViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        AppDelegate.shared.currentChatId = user.uid
        NewMessageHandler.customChatId = chat?.chatId ?? ""
        initTokens()
        registerEvents()
        if user.isGroupBool {
            updateGroupActive()
        }
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setTypingState(typingState: .NOT_TYPING)
        stopAudio()
        updatePresenceObservable?.dispose()
        removeKeyboardChangeObserver()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title = ""

        realmHelper = RealmHelper.getInstance(appRealm)
        
        senderUser = realmHelper.getUser(uid: FireManager.getUid())!
        
        messages = realmHelper.getMessagesInChat(chatId: user.uid)
        observableList = realmHelper.getObservableList(chatId: user.uid)
        
        initNetworkManagers()
        tblView.dataSource = self
        tblView.delegate = self
        
        textView.delegate = self
        
        textView.placeholderTextView.text = Strings.write_message
        setupSearchbar()
        
        setupNavigationItems()
        
        setUserInfo()
        listenForTypingState()
        listenForPresenceState()
        updateUnReadSentMessages()
        updateUnReadReceivedMessages()
        
        
        textView.placeholderColor = UIColor.lightGray
        btnSticker.addTarget(self, action: #selector(btnStickerTapped), for: .touchUpInside)
        
        setupStickerView()
        
        initToolbar()
        
        registerCells()
        
        setupRecordView()

        if user.isDeleted{
            hideOrShowTypingView(true)
            cantReplyLbl.text = Strings.cant_reply_chat
        }
        
        replyCancel.addTarget(self, action: #selector(cancelReplyDidClick), for: .touchUpInside)
        scrollDownView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(scrollDownViewTapped)))
        
        cancelSchedulingModeBtn.addTarget(self, action: #selector(cancelSchedulingModeBtnTapped), for: .touchUpInside)
        
        setBackground()
        
        navigationController?.hero.isEnabled = true
        
        enablePresence = true
        
        if user.isGroupBool {
            GroupManager.updateGroup(groupId: user.uid).subscribe(onCompleted: {
                RealmHelper.getInstance(appRealm).deletePendingGroupJob(groupId: self.user.uid)
            }).disposed(by: disposeBag)
        }
        
        proximitySensorHelper = ProximitySensorHelper(delegate: self)
        
        
        
        
        
        
        
        resetUnreadCount()
        
        cancelNotifications()
        
        fetchUserDataIfNeeded()
    }
    
    //MARK: - Custom Functions
    func setMessagesAsSeenLocally() {
        RealmHelper.getInstance(appRealm).setMessagesAsSeenLocally(chatId: user.uid)
    }
    
    //register EventBus events
    fileprivate func registerEvents() {
        //update network progress for uplaod/Download events
        SwiftEventBus.onMainThread(self, name: EventNames.networkProgressEvent) { event in
            guard let progressEventData = event?.object as? ProgressEventData, let index = self.messages?.getIndexById(messageId: progressEventData.id) else {
                return
            }
            
            let messageId = progressEventData.id
            
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = self.tblView.cellForRow(at: indexPath) as? BaseCell {
                let progress = progressEventData.progress
                cell.updateProgress(progress: progress)
                self.progressDict[messageId] = progress
            }
        }
        
        
        //update networkCompleteEvent for uplaod/Download events
        
        SwiftEventBus.onMainThread(self, name: EventNames.networkCompleteEvent) { event in
            guard let messageId = event?.object as? DownloadCompleteEvent, let index = self.messages?.getIndexById(messageId: messageId.id) else {
                return
            }
            
            let indexPath = IndexPath(row: index, section: 0)
            self.progressDict.removeValue(forKey: messageId.id)
            self.tblView.reloadRows(at: [indexPath], with: .none)
        }
        
        
        //set group isActive if it's changed
        SwiftEventBus.onMainThread(self, name: EventNames.updateGroupEvent) { event in
            guard let groupId = (event?.object as? UpdateGroupEvent)?.groupId else {
                return
            }
            if groupId != self.user.uid {
                return
            }
            
            self.updateGroupActive()
            
            
        }
        
        //if the app goes to background we will stop audio if it's playing
        SwiftEventBus.onMainThread(self, name: EventNames.appStateChangedEvent) { event in
            guard let state = event?.object as? UIApplication.State else {
                return
            }
            
            if state == .background {
                
                self.stopAudio()
                
            } else if state == .active {
                self.updateUnReadReceivedMessages()
                self.resetUnreadCount()
                self.cancelNotifications()
            }
            
        }
    }
    
    
    fileprivate func setupSearchbar() {
        
        searchBar = UISearchBar()
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        self.definesPresentationContext = true
    }
    
    fileprivate func setupRecordView() {
//        recordButton.recordView = recordView
//        recordView.delegate = self
        recorder = AudioRecorder()
    }
    
    fileprivate func initTokens() {
        notificationToken = messages?.observe { [weak self] (changes: RealmCollectionChange) in
            guard let strongSelf = self else {
                return
            }
            
            if !strongSelf.isLoadedd {
                strongSelf.isLoadedd = true
            } else {
                changes.updateTableView(tableView: strongSelf.tblView, noAnimationsOnUpdate: true)
            }
            
            
            switch changes {
                
                
            case .update(let messages, let deletions, let insertions, let modifications):
                
                //if the view was not loaded for the first time do NOT update tableView,instead just scroll to the bottom
                
                
                if insertions.count != 0 {
                    let message = messages[insertions[0]]
                    strongSelf.updateChat(message: message)
                }
            default: break
            }
            
            
            
        }
        
        observableListNotificationToken = observableList.observe({ [weak self] (changes: RealmCollectionChange) in
            guard let strongSelf = self else {
                return
            }
            
            
            switch changes {
                
                
            case .update(let messages, let deletions, let insertions, let modifications):
                
                for i in insertions {
                    let message = messages[i]
                    
                    if !strongSelf.user.isBroadcastBool && !strongSelf.user.isGroupBool && message.typeEnum != .GROUP_EVENT && message.fromId == FireManager.getUid() {
                        
                        FireManager.listenForSentMessagesState(receiverUid: strongSelf.user.uid, messageId: message.messageId, appRealm: appRealm).subscribe().disposed(by: strongSelf.disposeBag)
                    }
                    
                    //update incoming messages
                    // if this message is from the recipient and its' not read before then update the message currentTypingState to READ
                    if !strongSelf.user.isGroupBool && message.typeEnum != .GROUP_EVENT && message.typeEnum != .DATE_HEADER && message.fromId != FireManager.getUid() && message.chatId == strongSelf.user.uid && message.messageState != .READ {
                        
                        if UIApplication.shared.applicationState == .active {
                            //add a delay for 500ms, because while receiving a message it will scroll down while updating the message state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                FireManager.updateMessageState(messageId: message.messageId, chatId: message.chatId, state: .READ, appRealm: appRealm).subscribe().disposed(by: strongSelf.disposeBag)
                            }
                            
                        }
                    }
                    
                    
                }
                
                
            default:
                break
            }
            
            
        })
        
        if user.isGroupBool {
            
            observableGroupStateToken = realmHelper.getGroup(groupId: user.uid).observe({ [weak self] (changes: RealmCollectionChange) in
                guard let strongSelf = self else {
                    return
                }
                switch changes {
                    
                case .update(_, let deletions, let insertions, let modifications):
                    strongSelf.updateGroupActive()
                    
                default:
                    break
                }
            })
        }
        
    }
    
    fileprivate func stopAudio() {
        if audioPlayer != nil, audioPlayer.isPlaying(), audioPlayer.messageId != "", let index = messages.getIndexById(messageId: audioPlayer.messageId) {
            let indexPath = IndexPath(row: index, section: 0)
            updatePlayerState(state: .paused, messageId: audioPlayer.messageId, indexPath: indexPath)
        }
    }
    
    fileprivate func removeTokens() {
        notificationToken?.invalidate()
        notificationToken = nil
        observableListNotificationToken?.invalidate()
        observableListNotificationToken = nil
        observableGroupStateToken?.invalidate()
        observableGroupStateToken = nil
    }
    
   
    
    private func initNetworkManagers(){
        downloadManager = DownloadManager(disposeBag: disposeBag)
        uploadManager = UploadManager(disposeBag: disposeBag, messageEncryptor: MessageEncryptor(encryptionHelper: EncryptionHelper()))
        requestManager = RequestManager(disposeBag: disposeBag, downloadManager: downloadManager, uploadManager: uploadManager)
        scheduledMessagesManager = ScheduledMessagesManager(disposeBag: disposeBag)
    }
    
    private func setupStickerView(){
        kbStickerView = KBStickerView()
        kbStickerView.translatesAutoresizingMaskIntoConstraints = false
        let stickers = StickerBundleRetriever.getStickersFromBundle().map{Sticker (data: $0.path, resourceType: .assets)}
        
        
        let stickerCategories = [
            StickerCategory(stickers: stickers, icon: "ic_sticker", iconResourceType: .assets)
        ]
        
        let stickerProvider = StickerProvider(stickerCategories: stickerCategories, stickerDelegate: self, recentsEnabled: true)
        kbStickerView.stickerProvider = stickerProvider
        
    }
    private func fetchUserDataIfNeeded() {
        if !user.isGroupBool && !user.isBroadcastBool && user.status.isEmpty {
            FireManager.fetchUserByUid(uid: user.uid, appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
    }
    
    private func resetUnreadCount() {
        let oldBadge = chat?.unReadCount ?? 0
        let newBadge = BadgeManager.resetBadge(chatId: user.uid, oldBadge: oldBadge)
        UIApplication.shared.applicationIconBadgeNumber = newBadge
    }
    
    private func cancelNotifications() {
        let notificationsIds = Array(RealmHelper.getInstance(appRealm).getNotificationsByChatId(chatId: user.uid).map { $0.notificationId })
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: notificationsIds)
        RealmHelper.getInstance(appRealm).deleteNotificationsForChat(chatId: user.uid)
    }
    
    //set "you can't reply to this group if the group was not active"
    private func updateGroupActive() {
        guard let group = user.group else {
            return
        }
        if group.isActive {
            hideOrShowTypingView(false)
            
            if group.onlyAdminsCanPost {
                if !GroupManager.isAdmin(adminUids: group.adminUids) {
                    hideOrShowTypingView(true)
                    cantReplyLbl.text = Strings.only_admins_can_post
                } else {
                    hideOrShowTypingView(false)
                }
            }
            
        } else {
            hideOrShowTypingView(true)
            cantReplyLbl.text = Strings.cant_send_messages_to_group
            
        }
        
        
    }
    
    private func hideOrShowTypingView(_ hideTypingView: Bool) {
        cantReplyView.isHidden = !hideTypingView
        typingViewContainer.isHidden = hideTypingView
        recordButton.isHidden = hideTypingView
    }
    
    @objc private func scrollDownViewTapped() {
        scrollToLast()
    }
    
    @objc private func cancelSchedulingModeBtnTapped(){isInSchedulingMode = false}
    
    private func scrollToLast() {
        if messages.lastIndex() <= 0 {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13)
        {
            let numberOfRows = self.tblView.numberOfRows(inSection: 0)
            
            if numberOfRows > 0 {
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                self.tblView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
        
        hideUnreadCount();
        hideWithAnimation(true)
    }
    
    private func setBackground() {
        let wallpaper = UserDefaultsManager.getWallpaperPath()
        //if user has changed the wallpaper then load the wallpaper
        //otherwise stick with the default wallpaper which has been set in Storyboard
        if wallpaper != "" {
            backgroundView.image = UIImage(contentsOfFile: wallpaper)
        } else {
            backgroundView.image = UIImage(named: "background_hd")
        }
    }
    
    private func setTypingState(typingState: TypingState) {
        FireManager.setTypingStat(receiverUid: user.uid, stat: typingState, isGroup: user.isGroupBool, isBroadcast: user.isBroadcastBool).subscribe().disposed(by: disposeBag)
    }
    
    override func keyboardWillShow(keyboardFrame: CGRect?) {
        guard let keyboardRectangle = keyboardFrame else{
            return
        }
        let keyboardHeight = keyboardRectangle.height
        
        if isInSearchMode && searchBar.isFirstResponder{
            tableViewBottomConstraint.constant = (keyboardHeight / 1.4) + arrowsToolbar.frame.height / 2
        }
    }
    
    
    //move tableview down if user exits search mode
    override func keyBoardWillHide() {
        if !isInSearchMode {
            return
        }
        if tableViewBottomConstraint.constant != 16 {
            tableViewBottomConstraint.constant = 16
        }
    }
    
    
    
    //scroll to last OR update the unread count
    private func updateChat(message: Message) {
        
        if message.typeEnum == .GROUP_EVENT {
            return
        }
        
        //if the message was send by the user then scroll to last
        if message.fromId == FireManager.getUid() && message.messageState == .PENDING {
            scrollToLast()
        } else {
            //if the message was sent by Receiver and its state is still pending
            if message.chatId == user.uid && message.messageState == .PENDING {
                //get index from the message
                
                //if it's (not exists) return
                
                guard let i = messages.firstIndex(of: message) else {
                    return
                }
                
                
                //get last visible item on screen
                let lastVisibleItemPosition = tblView.lastVisibleRow
                
                //if the last message is visible then we will scroll to last
                //the user in this case is at before the last message that inserted
                // therefore a new message was inserted and we want to scroll to it
                //"-2" because one for index and one for previous message
                
                if messages.count - 2 == lastVisibleItemPosition {
                    scrollToLast()
                } else {
                    //otherwise the user may was checking another messages
                    //and for that we want to show the unreadCount badge with the count
                    
                    if lastVisibleItemPosition != i && message.messageId != previousMessageIdForScroll && message.typeEnum != MessageType.GROUP_EVENT {
                        unReadCount += 1
                        unreadMessagesLbl.text = "\(unReadCount)"
                        UIView.animate(withDuration: 0.2, animations: {
                            self.unreadMessagesLbl.isHidden = false
                        })
                        
                        hideWithAnimation(false)
                    }
                    previousMessageIdForScroll = message.messageId
                }
            }
        }
    }
    
    
    
    @objc private func dismissSearchBar() {
        setupNavigationItems()
    }
    
    private func disableOrEnableArrows() {
        
        if searchResults.isEmpty || searchIndex - 1 < 0 {
            upArrowItem.isEnabled = false
            //not found
        } else {
            upArrowItem.isEnabled = true
        }
        
        if searchResults.isEmpty || searchIndex + 2 > searchResults.count {
            //not found
            downArrowItem.isEnabled = false
            return
        } else {
            downArrowItem.isEnabled = true
            
        }
        
        
    }
    
    @objc private func upArrowTapped() {
        if searchResults.isEmpty || searchIndex - 1 < 0 {
            return
        }
        
        searchIndex -= 1
        let foundMessageId = searchResults[searchIndex].messageId
        let index = messages.getIndexById(messageId: foundMessageId)
        if let index = index {
            scrollAndHighlightSearch(index)
        }
        
        
        disableOrEnableArrows()
        
    }
    
    @objc private func downArrowTapped() {
        
        
        if searchResults.isEmpty || searchIndex + 2 > searchResults.count {
            //not found
            return
        }
        
        searchIndex += 1
        let foundMessageId = searchResults[searchIndex].messageId
        let index = messages.getIndexById(messageId: foundMessageId)
        if let index = index {
            scrollAndHighlightSearch(index)
        }
        
        disableOrEnableArrows()
    }
    
    
    fileprivate func animateTopToolbarLabelsTranslation(hideOnlineState: Bool, hideTypingStateLbl: Bool) {
        let hideUserName = hideOnlineState && hideTypingStateLbl
        
        let userNameTranslation: CGFloat = hideUserName ? 5 : 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.userNameLbl.transform = CGAffineTransform(translationX: 0, y: userNameTranslation)
        }, completion: nil)
    }
    
    private func setupNavigationItems(_ showSearchBar: Bool = false) {
        
        isInSearchMode = showSearchBar
        //disable auto keyboard management if it's in search mode
        IQKeyboardManager.shared.enable = false
        
        
        if showSearchBar {
            
            
            
            //get notifications for keyboardWillShow and keyboardWillHide
            listenForKeyboard = true
            
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            searchBar.widthAnchor.constraint(equalToConstant: view.frame.width - 25).isActive = true
            searchBar.heightAnchor.constraint(equalToConstant: 30).isActive = true
            
            
            let leftNavBarButton = UIBarButtonItem(customView: searchBar)
            self.navigationItem.leftBarButtonItem = leftNavBarButton
            self.navigationItem.rightBarButtonItem = nil
            navigationItem.leftItemsSupplementBackButton = false
            
            searchBar.becomeFirstResponder()
            
            
            arrowsToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            arrowsToolbar.barStyle = .default
            
            upArrowItem = UIBarButtonItem(image: UIImage(named: "arrow_up"), style: .plain, target: self, action: #selector(upArrowTapped))
            downArrowItem = UIBarButtonItem(image: UIImage(named: "arrow_down"), style: .plain, target: self, action: #selector(downArrowTapped))
            arrowsToolbar.items = [upArrowItem, downArrowItem]
            arrowsToolbar.sizeToFit()
            searchBar.inputAccessoryView = arrowsToolbar
            
            
        } else {
            
            listenForKeyboard = false

            navigationItem.leftItemsSupplementBackButton = true
            self.navigationController?.navigationBar.backItem?.title = ""
            self.navigationItem.title = ""
            
            
            if userImgView == nil {
                userImgView = EnhancedCircleImageView()
                userImgView.contentMode = .scaleAspectFit
                
                
                userImgView.isUserInteractionEnabled = true
                
                userImgView.hero.id = user.uid
                userImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userImgTapped)))
            }
            
            if userNameLbl == nil {
                userNameLbl = UILabel(text: "John Doe Lorem ipsum Hello World long text....")
                userNameLbl.font = userNameLbl.font.withSize(14)
                userNameLbl.isUserInteractionEnabled = true
                userNameLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userNameStackTapped)))
            }
            
            typingStateLbl = UILabel(text: "")
            typingStateLbl.font = typingStateLbl.font.withSize(10)
            typingStateLbl.isUserInteractionEnabled = true
            typingStateLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userNameStackTapped)))
            
            availableStateLbl = UILabel(text: "")
            
            availableStateLbl.font = availableStateLbl.font.withSize(10)
            
            let statesLblsStack = UIStackView(arrangedSubviews: [typingStateLbl, availableStateLbl])
            statesLblsStack.isUserInteractionEnabled = true
            
            
            let userNameAndStateStack = UIStackView(arrangedSubviews: [userNameLbl, statesLblsStack])
            
            userNameAndStateStack.axis = .vertical
            userNameAndStateStack.spacing = 4
            
            userNameAndStateStack.isUserInteractionEnabled = true
            userNameAndStateStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userNameStackTapped)))
            
            let leftItemsContainer = UIView()
            
            userNameAndStateStack.translatesAutoresizingMaskIntoConstraints = false
            userImgView.translatesAutoresizingMaskIntoConstraints = false
            
            leftItemsContainer.addSubview(userImgView)
            leftItemsContainer.addSubview(userNameAndStateStack)
            
            userImgView.leftAnchor.constraint(equalTo: leftItemsContainer.leftAnchor).isActive = true
            userImgView.widthAnchor.constraint(equalToConstant: 40).isActive = true
            userImgView.bottomAnchor.constraint(equalTo: leftItemsContainer.bottomAnchor).isActive = true
            userImgView.topAnchor.constraint(equalTo: leftItemsContainer.topAnchor).isActive = true
            
            
            userNameAndStateStack.leftAnchor.constraint(equalTo: userImgView.rightAnchor, constant: 8).isActive = true
            
            userNameAndStateStack.topAnchor.constraint(equalTo: leftItemsContainer.topAnchor, constant: 4).isActive = true
            userNameAndStateStack.rightAnchor.constraint(equalTo: leftItemsContainer.rightAnchor, constant: 4).isActive = true
            
            
            let leftItem = UIBarButtonItem(customView: leftItemsContainer)
            navigationItem.setLeftBarButton(leftItem, animated: false)
            
            
            //add call & videoCall if it's not a group and not a Broadcast
            if enableVideoAndVoiceCallsBtns {
                
                let voiceCallBtn = UIButton(image: UIImage(named: "call")!.resized(to: CGSize(width: 30, height: 30)))
                let videoCallBtn = UIButton(image: UIImage(named: "video")!.resized(to: CGSize(width: 30, height: 30)))
                voiceCallBtn.addTarget(self, action: #selector(voiceCallTapped), for: .touchUpInside)
                videoCallBtn.addTarget(self, action: #selector(videoCallTapped), for: .touchUpInside)
                
                let rightButtonsStackView = UIStackView(arrangedSubviews: [voiceCallBtn, videoCallBtn])
                rightButtonsStackView.spacing = 8
                
                callingButtonsNavigation = UIBarButtonItem(customView: rightButtonsStackView)
                
                navigationItem.setRightBarButton(callingButtonsNavigation, animated: false)
            }
            
            
        }
    }
    
    private var enableVideoAndVoiceCallsBtns:Bool{
        if user.isDeleted{
            return false
        }
        
        if !user.isGroupBool && !user.isBroadcastBool{
            return true
        }
        
        if let group = user.group , group.users.count <= Config.maxGroupCallCount{
            return true
        }
        
        return false
    }
    
    
    @objc private func voiceCallTapped() {
        let callType = user.isGroupBool ? CallType.CONFERENCE_VOICE : CallType.VOICE
        makeACall(user: user, callType: callType)
    }
    
    @objc private func videoCallTapped() {
        let callType = user.isGroupBool ? CallType.CONFERENCE_VIDEO : CallType.VIDEO
        makeACall(user: user, callType: callType)
    }
    
    //go to user's info VC
    @objc private func userNameStackTapped() {
        if isInSelectMode {
            return
        }
        
        if user.isBroadcastBool {
            performSegue(withIdentifier: "toBroadcastInfo", sender: nil)
        } else {
            let segueIdentifier = user.isGroupBool ? "toGroupDetails" : "toUserDetails"
            performSegue(withIdentifier: segueIdentifier, sender: nil)
        }
    }
    
    //preview user's image
    @objc private func userImgTapped() {
        if !user.isBroadcastBool {
            performSegue(withIdentifier: "toPreviewUserImage", sender: nil)
        }
        
    }
    
    
    
    
    //MARK: - Tableview methods
    //registering TableViewCells
    private func registerCells() {
        tblView.registerCellNib(cellClass: SentTextCell.self)
        tblView.registerCellNib(cellClass: SentTextQuotedCell.self)
        tblView.registerCellNib(cellClass: ReceivedTextCell.self)
        tblView.registerCellNib(cellClass: SentImageCell.self)
        tblView.registerCellNib(cellClass: SentVideoCell.self)
        tblView.registerCellNib(cellClass: SentVoiceCell.self)
        tblView.registerCellNib(cellClass: SentAudioCell.self)
        tblView.registerCellNib(cellClass: SentContactCell.self)
        tblView.registerCellNib(cellClass: SentLocationCell.self)
        tblView.registerCellNib(cellClass: SentFileCell.self)
        tblView.registerCellNib(cellClass: SentFileQuotedCell.self)
        
        tblView.registerCellNib(cellClass: ReceivedImageCell.self)
        tblView.registerCellNib(cellClass: ReceivedVoiceCell.self)
        tblView.registerCellNib(cellClass: ReceivedContactCell.self)
        tblView.registerCellNib(cellClass: ReceivedContactQuotedCell.self)
        tblView.registerCellNib(cellClass: ReceivedVideoCell.self)
        tblView.registerCellNib(cellClass: ReceivedLocationCell.self)
        tblView.registerCellNib(cellClass: ReceivedAudioCell.self)
        tblView.registerCellNib(cellClass: ReceivedFileCell.self)
        
        tblView.registerCellNib(cellClass: GroupEventCell.self)
        tblView.registerCellNib(cellClass: DateHeaderCell.self)
        
        tblView.registerCellNib(cellClass: SentDeletedMessageCell.self)
        tblView.registerCellNib(cellClass: ReceivedDeletedMessageCell.self)
        
        tblView.registerCellNib(cellClass: SentStickerCell.self)
        tblView.registerCellNib(cellClass: ReceivedStickerCell.self)
        
        tblView.registerCellNib(cellClass: UnSupportedCell.self)
        
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let message = messages[indexPath.row]
        
        if message.typeEnum == .DATE_HEADER {
            return nil
        }
        
        if contextSelectedItemType == .forward {
            if message.typeEnum.isText()
                || message.typeEnum.isContact()
                || message.typeEnum.isLocation() {
            } else if message.downloadUploadState != .SUCCESS {
                return nil
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        if message.typeEnum == .DATE_HEADER {
            return
        }
        
        
        if !selectedItems.contains(message) {
            selectedItems.append(message)
        }
        
        toolbarTitle.text = "\(selectedItems.count)"
        
        
        if let cell = tblView.cellForRow(at: indexPath) as? BaseCell {
            cell.isMessageSelected = true
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        selectedItems.removeAll(where: { $0.messageId == message.messageId })
        
        toolbarTitle.text = "\(selectedItems.count)"
        
        if let cell = tblView.cellForRow(at: indexPath) as? BaseCell {
            cell.isMessageSelected = false
        }
        
        
        if selectedItems.count == 0 {
            isInSelectMode = false
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages![indexPath.row]
        
        switch message.typeEnum {
        case .RECEIVED_TEXT:
            let cell = tableView.dequeue() as ReceivedTextCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .SENT_IMAGE:
            let cell = tableView.dequeue() as SentImageCell
            cell.bind(message: message, user: user)
            initCell(cell: cell, indexPath: indexPath)
            
            cell.imageContent.hero.id = message.messageId
            cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
            cell.imageContent.isOpaque = true
            return cell
            
        case .SENT_TEXT:
            var cell: BaseCell!
            if message.quotedMessage == nil {
                cell = tableView.dequeue() as SentTextCell
            } else {
                cell = tableView.dequeue() as SentTextQuotedCell
            }
            
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .SENT_VIDEO:
            let cell = tableView.dequeue() as SentVideoCell
            cell.hero.id = message.messageId
            cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
            
        case .SENT_VOICE_MESSAGE:
            let cell = tableView.dequeue() as SentVoiceCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user, userImage: senderUser.thumbImg.toUIImage())
            initVoiceCell(message, cell)
            return cell
            
            
        case .SENT_STICKER:
            let cell = tableView.dequeue() as SentStickerCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .SENT_AUDIO:
            let cell = tableView.dequeue() as SentAudioCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            initVoiceCell(message, cell)
            return cell
            
            
        case .SENT_CONTACT:
            let cell = tableView.dequeue() as SentContactCell
            cell.delegate = self
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .SENT_LOCATION:
            let cell = tableView.dequeue() as SentLocationCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .SENT_FILE:
            var cell: BaseCell!
            if message.quotedMessage == nil {
                cell = tableView.dequeue() as SentFileCell
            } else {
                cell = tableView.dequeue() as SentFileQuotedCell
            }
            
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .GROUP_EVENT:
            let cell = tableView.dequeue() as GroupEventCell
            
            if let group = user.group {
                let text = GroupEvent.extractString(messageContent: message.content, users: group.users)
                cell.bind(text: text)
            }
            
            return cell
            
        case .DATE_HEADER:
            let cell = tableView.dequeue() as DateHeaderCell
            
            cell.bind(message: message)
            
            return cell
            
        case .RECEIVED_IMAGE:
            let cell = tableView.dequeue() as ReceivedImageCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            cell.imageContent.hero.id = message.messageId
            cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
            cell.imageContent.isOpaque = true
            return cell
            
            
        case .RECEIVED_VOICE_MESSAGE:
            let cell = tableView.dequeue() as ReceivedVoiceCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            initVoiceCell(message, cell)
            return cell
            
            
        case .RECEIVED_CONTACT:
            var cell: ReceivedContactCell!
            if message.quotedMessage == nil {
                cell = tableView.dequeue() as ReceivedContactCell
            } else {
                cell = tableView.dequeue() as ReceivedContactQuotedCell
            }
            
            cell.delegate = self
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .RECEIVED_VIDEO:
            let cell = tableView.dequeue() as ReceivedVideoCell
            cell.hero.id = message.messageId
            cell.imageContent.hero.modifiers = [.fade, .scale(0.8)]
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .RECEIVED_AUDIO:
            let cell = tableView.dequeue() as ReceivedAudioCell
            initCell(cell: cell, indexPath: indexPath)
            
            cell.bind(message: message, user: user)
            initVoiceCell(message, cell)
            return cell
            
        case .RECEIVED_LOCATION:
            let cell = tableView.dequeue() as ReceivedLocationCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
            
        case .RECEIVED_FILE:
            let cell = tableView.dequeue() as ReceivedFileCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
            
        case .RECEIVED_STICKER:
            let cell = tableView.dequeue() as ReceivedStickerCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .SENT_DELETED_MESSAGE:
            let cell = tableView.dequeue() as SentDeletedMessageCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        case .RECEIVED_DELETED_MESSAGE:
            let cell = tableView.dequeue() as ReceivedDeletedMessageCell
            initCell(cell: cell, indexPath: indexPath)
            cell.bind(message: message, user: user)
            return cell
            
        default:
            let cell = tableView.dequeue() as UnSupportedCell
            cell.bind(message: message, user: user)
            return cell
            
        }
    }
    
    // add spacing for last item
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 20))
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    
    func initCell(cell: BaseCell, indexPath: IndexPath) {
        cell.isInSelectMode = isInSelectMode
        if let message = messages.getItemSafely(index: indexPath.row) as? Message {
            cell.isMessageSelected = selectedItems.contains(message)
        }
        
        
        cell.cellDelegate = self
        cell.indexPath = indexPath
        
        if let message = messages.getItemSafely(index: indexPath.row) as? Message {
            let messageId = message.messageId
            if let progress = progressDict[messageId] {
                cell.updateProgress(progress: progress)
            } else {
                cell.progressButton?.progress = 0
            }
            
            cell.progressButton?.isHidden = message.downloadUploadState == .SUCCESS
        }
    }
    
    fileprivate func initVoiceCell(_ message: Message, _ cell: AudioBase) {
        cell.delegate = self
        
        if let audioProgress = audioProgressDict[message.messageId] {
            cell.updateSlider(currentProgress: audioProgress.currentProgress, duration: audioProgress.duration, currentDurationStr: nil)
            cell.playerState = audioProgress.playerState
        } else {
            cell.updateSlider(currentProgress: 0, duration: 0, currentDurationStr: message.mediaDuration)
            cell.playerState = .paused
        }
        
        
    }

    
   
    
    //send text message
    fileprivate func sendScheduledMessage(_ message: Message) {
        let time = Date().currentTimeMillisLong()
        
        let scheduledMessage = ScheduledMessage.messageToScheduledMessage(message, user: self.user, scheduledAt: time, timeToExecute: schedulingDate.currentTimeMillisLong(),status:.uploading)
        
        realmHelper.saveObjectToRealm(object: scheduledMessage)
        let messageType = message.typeEnum
        if !messageType.isMediaType(){
            scheduledMessagesManager.sendScheduledMessageMessage(scheduledMessage: scheduledMessage, callback: nil)
        }else{
            scheduledMessagesManager.uploadScheduledMessage(scheduledMessage: scheduledMessage, callback: nil)
        }
        showAlert(type: .success, message: "Message Scheduled")
    }

    func sendMessage(textMessage: String) {
        if textMessage.lengthOfBytes(using: .utf8) > FireConstants.MAX_SIZE_STRING {
            showAlert(type: .error, message: Strings.message_is_too_big)
            return
        }
        
        if textMessage.isEmpty {
            return
        }
        let message = MessageCreator(user: user, type: .SENT_TEXT, appRealm: appRealm).quotedMessage(getQuotedMessage()).text(textMessage).schedulingMode(bool: isInSchedulingMode).build()

        textView.clear()
        if isInSchedulingMode {
            sendScheduledMessage(message)
        } else {
            requestManager.request(message: message, callback: nil, appRealm: appRealm)
        }
        
        setTypingState(typingState: .NOT_TYPING)
        recordButton.animate(state: .toRecord)
        pushNotificationCreateMessage(groupId: message.toId, userName: user.userName, message: textMessage)
    }
    
    func sendVideo(video: AVPlayerItem?, isFromCamera: Bool) {
        guard let videoItem = video, let assetUrl = videoItem.asset as? AVURLAsset else {
            return
        }
        
        let videoExt = assetUrl.url.pathExtension
        let outputUrl = DirManager.generateFile(type: .SENT_VIDEO)
        if videoExt != "mp4" {
            VideoUtil.exportAsMp4(inputUrl: assetUrl.url, outputUrl: outputUrl) {
                
                DispatchQueue.main.async {
                    let message = MessageCreator(user: self.user, type: .SENT_VIDEO, appRealm: appRealm).quotedMessage(self.getQuotedMessage()).schedulingMode(bool: self.isInSchedulingMode).path(outputUrl.path).copyVideo(false, deleteVideoOnComplete: false).build()
                    //
                    //delete VideoFile if it was saved directly from Camera (tmp directory)
                    
                    if self.isInSchedulingMode{
                        self.sendScheduledMessage(message)
                    }else{
                        self.uploadManager.upload(message: message, callback: nil, appRealm: appRealm)
                    }
                    if isFromCamera {
                        try? assetUrl.url.deleteFile()
                    }
                    
                    self.cancelReplyDidClick()
                }
            }
        } else {
            let message = MessageCreator(user: user, type: .SENT_VIDEO, appRealm: appRealm).quotedMessage(getQuotedMessage()).schedulingMode(bool: isInSchedulingMode).path(assetUrl.url.path).copyVideo(true, deleteVideoOnComplete: isFromCamera).build()
            
            if isInSchedulingMode{
                sendScheduledMessage(message)
            }else{
                uploadManager.upload(message: message, callback: nil, appRealm: appRealm)
            }
            self.cancelReplyDidClick()
        }
    }
    
    private func sendImage(data: Data, previewImage: UIImage? = nil) {
        
        let message = MessageCreator(user: user, type: .SENT_IMAGE, appRealm: appRealm).quotedMessage(getQuotedMessage()).schedulingMode(bool: isInSchedulingMode).image(imageData: data, thumbImage: previewImage).build()
        
        
        if  isInSchedulingMode{
            sendScheduledMessage(message)
        }else{
            requestManager.request(message: message, callback: nil, appRealm: appRealm)
        }
        cancelReplyDidClick()
    }
    
    private func sendSticker(stickerPath:String){
        let message = MessageCreator(user: user, type: .SENT_STICKER, appRealm: appRealm).quotedMessage(getQuotedMessage()).schedulingMode(bool: isInSchedulingMode).path(stickerPath).build()
        
        
        if  isInSchedulingMode{
            sendScheduledMessage(message)
        }else{
            requestManager.request(message: message, callback: nil, appRealm: appRealm)
        }
        cancelReplyDidClick()
    }
    
    
    
    //getQuotedMessage if available
    private func getQuotedMessage() -> Message? {
        if replyLayout.isHidden {
            return nil
        }
        
        return currentQuotedMessage
    }
    
    //this will be called when a user taps on the Cell's view itself NOT outside it
    
    private func selectOrDeselectItem(indexPath: IndexPath, message: Message) {
        
        
        if canForwardOrShare(message: message) {
            if selectedItems.contains(message) {
                tableView(tblView, didDeselectRowAt: indexPath)
            } else {
                tableView(tblView, didSelectRowAt: indexPath)
            }
        }
    }
    
    private func canForwardOrShare(message: Message) -> Bool {
        var canForwardOrShareBool = false
        
        switch message.typeEnum {
            
        case .SENT_TEXT, .RECEIVED_TEXT, .SENT_CONTACT, .RECEIVED_CONTACT, .SENT_LOCATION, .RECEIVED_LOCATION:
            //ADD FORWARD ITEM
            canForwardOrShareBool = true
        case .SENT_DELETED_MESSAGE, .RECEIVED_DELETED_MESSAGE:
            canForwardOrShareBool = false
        default:
            
            if message.downloadUploadState == .SUCCESS || message.downloadUploadState == .DEFAULT {
                //ADD FORWARD
                canForwardOrShareBool = true
            } else {
                //REMOVE REPLY
                canForwardOrShareBool = false
            }
        }
        return canForwardOrShareBool
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let controller = segue.destination as? CameraVCViewController {
            Permissions.requestCameraPermissions(completion: { isAuthorized in
                if isAuthorized {
                    controller.delegate = self
                    controller.transitioningDelegate = self
                    controller.modalPresentationStyle = .custom
                    controller.interactiveTransition = self.interactiveTransition
                    self.interactiveTransition.attach(to: controller)
                }
            })
            
        } else if let controller = segue.destination as? UserDetailsBase {
            controller.initialize(user: user, self)
        } else if let controller = segue.destination as? BroadcastInfoTableVC {
            controller.initialize(user: user)
        } else if let controller = segue.destination as? PreviewUserImage {
            controller.initialize(user: user)
        } else if let controller = segue.destination as? ChatViewController, let user = sender as? User {
            controller.initialize(user: user)
        } else if let controller = segue.destination as? ForwardVC {
            controller.messages = selectedItems
        }else if let controller = segue.destination as? ViewStatusVC, let tuple = sender as? ([Status],User){
            let (statuses,user) = tuple
            controller.initialize(statuses: statuses,user: user)
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }
    
    
    
    //init bottomToolbar when user selects a Cell in TableView
    func initToolbar() {
        leftButtonToolbar = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(toolbarTrashDidClick))
        let leftSpacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarTitle = ToolBarTitleItem(text: "", font: .systemFont(ofSize: 16), color: .black)
        let rightSpacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        rightButtonToolbar = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(toolbarShareDidClick))
        toolbar.items = [leftButtonToolbar, leftSpacing, toolbarTitle, rightSpacing, rightButtonToolbar]
        
    }
    
    @objc func toolbarTrashDidClick() {
        let alert = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
        let deleteForMeAction = UIAlertAction(title: Strings.deleteForMe, style: .destructive) { (_) in
            self.realmHelper.deleteMessages(messages: self.selectedItems)
            self.selectedItems.removeAll()
            self.isInSelectMode = false
        }
        
        //check the file type && check for time is passed (can user delete this message for everyone).
        let canDeleteForAll = selectedItems.filter { (message) -> Bool in
            return message.messageState == .PENDING || !message.typeEnum.isSentType() || message.typeEnum.isDeletedMessage() || TimeHelper.isMessageTimePassed(serverTime: Date(), messageTime: message.timestamp.toDate())
        }.count == 0
        
        let deleteForEveryoneAction = UIAlertAction(title: Strings.delete_for_everyone, style: .destructive) { (_) in
            MessageDeleter.deleteMessagesForEveryone(messages: self.selectedItems, user: self.user, appRealm: appRealm).subscribe().disposed(by: self.disposeBag)
            
            self.selectedItems.removeAll()
            self.isInSelectMode = false
            
        }
        
        if canDeleteForAll {
            alert.addAction(deleteForEveryoneAction)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteForMeAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    @objc func toolbarForwardDidClick() {
        performSegue(withIdentifier: "toForwardVC", sender: nil)
        cancelActionMode()
    }
    
    @objc func toolbarShareDidClick() {
        
        
        //get list of messages and convert it to shareableItems
        let itemsToShare = selectedItems.sorted(by: { $0.timestamp < $1.timestamp }).map { message -> Any in
            let type = message.typeEnum
            if type.isText() {
                return message.content
            } else if type.isContact(), let contact = message.contact {
                if let vcard = contact.toCNContact().convertToVcfAndGetFile() {
                    return vcard
                }
                return Void()
                
            } else if type.isLocation(), let location = message.location {
                
                return location.toShareableURL()
                
            } else {
                return URL(fileURLWithPath: message.localPath)
            }
        }
        
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    //animating cameraBtn
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        let center = typingViewContainer.convert(btnCamera.center, to: view)
        transition.startingPoint = center
        transition.bubbleColor = .black
        return transition
    }
    
    //animating cameraBtn
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let center = typingViewContainer.convert(btnCamera.center, to: view)
        
        transition.transitionMode = .dismiss
        transition.startingPoint = center
        transition.bubbleColor = .black
        return transition
    }
    
    //animating cameraBtn
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
    
    
    
    //dismiss reply layout
    @objc private func cancelReplyDidClick() {
        replyLayoutBottomConstraint.constant = -2000
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.replyLayout.isHidden = true
        })
        
        currentQuotedMessage = nil
    }
    
    
    fileprivate func setContentOffset() {
        tblView.setContentOffset(CGPoint(x: 0, y: tblView.contentSize.height - tblView.frame.size.height), animated: true)
    }
    
    
    private func setUserInfo() {
        userNameLbl.text = user.isDeleted ? Strings.deleted  : user.userName
        if user.isBroadcastBool {
            userImgView.image = UIImage(named: "rss")
        }else if user.isDeleted {
            userImgView.image = UIImage(named: "profile")
        } else {
            userImgView.image = user.thumbImg.toUIImage()
        }
        
        if let group = user.group {
            if group.isActive {
                setMembersInToolbar()
            }
        }
    }
    
    private func listenForTypingState() {
        if user.isBroadcastBool {
            return
        }
        
        
        if user.isGroupBool {
            if let group = user.group, group.isActive {
                //listen for groupTyping events if a certain user is typing
                GroupTyping(groupId: user.uid, users: group.users, disposeBag: disposeBag, delegate: self)
                
            }
        } else {
            FireManager.listenForTypingState(uid: user.uid).subscribe(onNext: { (state) in
                self.currentReceiverTypingState = state
                
                
                if state == .NOT_TYPING {
                    
                    //updateLabelsVisibility
                    self.updateToolbarLabelsVisibility(hideOnlineStatToolbar: false)
                    
                    self.setCurrentPresenceState(state: self.currentReceiverOnlineState)
                } else if state == .RECORDING || state == .TYPING {
                    self.typingStateLbl.text = state.getStatString()
                    //updateLabelsVisibility
                    self.updateToolbarLabelsVisibility(hideOnlineStatToolbar: true)
                    
                }
                
                
            }).disposed(by: disposeBag)
            
        }
    }
    
    private func listenForPresenceState() {
        if user.isBroadcastBool || user.isGroupBool {
            return
        }
        
        
        FireManager.listenForPresence(uid: user.uid).subscribe(onNext: { (state) in
            self.currentReceiverOnlineState = state
            
            
            if self.currentReceiverTypingState == .NOT_TYPING {
                
                if state.isOnline {
                    self.availableStateLbl.text = state.getOnlineString()
                } else {
                    self.availableStateLbl.text = TimeHelper.getTimeAgo(timestamp: String(state.lastSeen).toDate())
                }
                self.updateToolbarLabelsVisibility(hideOnlineStatToolbar: false)
                
            }
            
            
            
        }).disposed(by: disposeBag)
        
        
    }
    
    private func setCurrentPresenceState(state: PresenceState) {
        if state.isOnline {
            self.availableStateLbl.text = state.getOnlineString()
        } else {
            self.availableStateLbl.text = TimeHelper.getTimeAgo(timestamp: String(state.lastSeen).toDate())
        }
    }
    
    var unreadmessagesCount = 0
    private func updateUnReadSentMessages() {
        if user.isGroupBool || user.isBroadcastBool {
            return
        }
        
        let unreadMessages = RealmHelper.getInstance(appRealm).getUnreadAndUnDeliveredSentMessages(chatId: user.uid, senderId: FireManager.getUid())
        
        
        for message in unreadMessages {
            FireManager.listenForSentMessagesState(receiverUid: user.uid, messageId: message.messageId, appRealm: appRealm).subscribe().disposed(by: disposeBag)
            unreadmessagesCount += 1
        }
        
        let unReadVoiceMessages = RealmHelper.getInstance(appRealm).getUnReadVoiceMessages(chatId: user.uid)
        
        for unReadVoiceMessage in unReadVoiceMessages {
            FireManager.listenForSentVoiceMessagesState(receiverUid: user.uid, messageId: unReadVoiceMessage.messageId, appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
    }
    
    
    private func updateUnReadReceivedMessages() {
        if user.isGroupBool || user.isBroadcastBool {
            return
        }
        
        let unreadMessages = RealmHelper.getInstance(appRealm).getUnReadReceivedMessages(chatId: user.uid)
        for message in unreadMessages {
            FireManager.updateMessageState(messageId: message.messageId, chatId: message.chatId, state: .READ, appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
    }
    
    //set incoming messages to read
    private func updateIncomingMessagesState() {
        if user.isBroadcastBool {
            return
        }
        
        if user.isGroupBool {
            //set received messages as read
            RealmHelper.getInstance(appRealm).setMessagesAsReadLocally(chatId: user.uid)
        } else {
            //update received messages as read in Server
            FireManager.setMessagesAsRead(chatId: user.uid, appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
    }
    
    
    private func updateToolbarLabelsVisibility(hideOnlineStatToolbar: Bool) {
        
        if isInSelectMode || isInSearchMode {
            return
        }
        
        
        if (user.isGroupBool || user.isBroadcastBool) {
            typingStateLbl.isHidden = !hideOnlineStatToolbar
            availableStateLbl.isHidden = hideOnlineStatToolbar
            
            
        } else {
            typingStateLbl.isHidden = !hideOnlineStatToolbar
            availableStateLbl.isHidden = hideOnlineStatToolbar
            
            let hideOnline = availableStateLbl.isHidden || currentReceiverOnlineState.lastSeen == 0
            
            
            animateTopToolbarLabelsTranslation(hideOnlineState: !hideOnline, hideTypingStateLbl: !hideOnlineStatToolbar)
            
            
        }
        
        
        
    }
    
    
    func initialize(user: User, delegate: ChatVCDelegate? = nil) {
        self.user = user
        self.delegate = delegate
        chat = RealmHelper.getInstance(appRealm).getChat(id: user.uid)
        
    }
    
    private func addKeyboardChangeObserver(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    private func removeKeyboardChangeObserver(){
        NotificationCenter.default.removeObserver(self, name:UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc private func keyboardWillChange(notification:Notification){
        
        guard !isInSearchMode,
              let userInfo = notification.userInfo,
              let animationCurveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              
                let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else{return}
        let screen = UIScreen.main.bounds
        
        let newBottomConstraint = screen.size.height - keyboardEndFrame.origin.y
        
        let oldYContentOffset = tblView.contentOffset.y
        let oldTableViewHeight = tblView.bounds.size.height
        
        let animationCurve = UIView.AnimationOptions(rawValue:animationCurveValue)
        
        
        UIView.animate(withDuration: animationDuration, delay: 0,options:animationCurve ) {
            self.typingViewBottomLayoutConstraint.constant = newBottomConstraint
            self.view.layoutIfNeeded()
            
            let newTableViewHeight = self.tblView.bounds.size.height
            let contentSizeHeight = self.tblView.contentSize.height
            var newYContentOffset = oldYContentOffset - newTableViewHeight + oldTableViewHeight
            
            let possibleBottommostYContentOffset = contentSizeHeight - newTableViewHeight
            newYContentOffset = min(newYContentOffset, possibleBottommostYContentOffset)
            let possibleTopmostYContentOffset = 0
            newYContentOffset = max(CGFloat(possibleTopmostYContentOffset), newYContentOffset);
            
            let newTableViewContentOffset = CGPoint(x:self.tblView.contentOffset.x, y:newYContentOffset)
            self.tblView.contentOffset = newTableViewContentOffset
            
        }
    }
    
}


extension ChatViewController: AudioCellDelegate {
    fileprivate func initAudioPlayer(_ message: Message, currentProgress: Float) {
        
        
        let url = URL(fileURLWithPath: message.localPath)
        
        audioPlayer = AudioPlayer(url: url, messageId: message.messageId, speakerType: .speaker)
        audioPlayer.delegate = self
        
        if currentProgress != 0 {
            audioPlayer.seek(to: TimeInterval(currentProgress))
        }
    }
    
    
    func didFinish(messageId: String) {
        if let index = messages?.getIndexById(messageId: messageId) {
            let indexPath = IndexPath(row: index, section: 0)
            updatePlayerState(state: .paused, messageId: messageId, indexPath: indexPath)
            tblView.reloadRows(at: [indexPath], with: .none)
            
        }
        
    }
    
    func didClickPlayButton(indexPath: IndexPath, currentProgress: Float) {
        
        guard let message = self.messages?[indexPath.row] else {
            return
        }
        
        if isInSelectMode {
            selectOrDeselectItem(indexPath: indexPath, message: message)
            return
        }
        
        if !FileUtil.exists(at: message.localPath) {
            showAlert(type: .error, message: Strings.file_not_exists)
            return
        }
        
        if audioPlayer == nil {
            initAudioPlayer(message, currentProgress: currentProgress)
        }
        
        //set voice message as seen
        if message.typeEnum == .RECEIVED_VOICE_MESSAGE && !message.voiceMessageSeen {
            FireManager.updateVoiceMessageStat(messageId: message.messageId, appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
        
        //if it's a new audio
        if audioPlayer.messageId != message.messageId {
            //pause the old player
            if let oldIndex = messages?.getIndexById(messageId: audioPlayer.messageId) {
                updatePlayerState(state: .paused, messageId: audioPlayer.messageId, indexPath: IndexPath(row: oldIndex, section: 0))
            }
            
            initAudioPlayer(message, currentProgress: currentProgress)
        }
        
        
        let playerState: PlayerState = audioPlayer.isPlaying() ? .paused : .playing
        updatePlayerState(state: playerState, messageId: message.messageId, indexPath: indexPath)
    }
    
    //update audio player state
    func updatePlayerState(state: PlayerState, messageId: String, indexPath: IndexPath) {
        
        if state == .playing {
            proximitySensorHelper.setProximitySensorEnabled(true)
            audioPlayer.play()
        } else {
            proximitySensorHelper.setProximitySensorEnabled(false)
            audioPlayer.pause()
        }
        
        if let audioProgress = audioProgressDict[messageId] {
            audioProgress.playerState = state
            audioProgressDict[messageId] = audioProgress
        } else {
            audioProgressDict[messageId] = AudioProgress(currentProgress: 0, duration: 0, playerState: state)
        }
        
        
        if let cell = tblView.cellForRow(at: indexPath) as? AudioBase {
            cell.playerState = state
        }
        
        
    }
    
    func didSeek(indexPath: IndexPath, to value: Float) {
        if audioPlayer == nil {
            return
        }
        
        audioPlayer.seek(to: TimeInterval(value))
        
        
    }
    
}

extension ChatViewController: AudioPlayerDelegate {
    func didUpdate(currentProgress: TimeInterval, duration: TimeInterval, messageId: String) {
        guard let index = messages?.getIndexById(messageId: messageId) else {
            return
        }
        
        audioProgressDict[messageId] = AudioProgress(currentProgress: currentProgress, duration: duration, playerState: .playing)
        
        let indexPath = IndexPath(item: index, section: 0)
        if let cell = tblView.cellForRow(at: indexPath) as? AudioBase {
            cell.updateSlider(currentProgress: currentProgress, duration: duration, currentDurationStr: nil)
        }
        
    }
    
    
}


extension ChatViewController: ContactCellDelegate {
    func didClickSave(at index: IndexPath) {
        
        guard let message = messages?[index.row] else {
            return
        }
        
        if isInSelectMode {
            selectOrDeselectItem(indexPath: index, message: message)
            return
        }
        
        let realmContact = message.contact!
        
        
        let controller = CNContactViewController(forNewContact: realmContact.toCNContact())
        controller.delegate = self
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true)
        
        
    }
    
    func didClickMessage(at index: IndexPath) {
        let message = messages[index.row]
        if let contact = message.contact {
            if contact.realmList.count > 1 {
                let alert = properAlert(title: Strings.choose_anumber, message: nil, preferredStyle: .actionSheet)
                for number in contact.realmList {
                    let action = UIAlertAction(title: number.number, style: .default) { (_) in
                        self.isHasFireApp(phone: number.number)
                    }
                    alert.addAction(action)
                }
                self.present(alert, animated: true, completion: nil)
            } else {
                self.isHasFireApp(phone: contact.realmList[0].number)
            }
            
            
        }
        
        
    }
    
    //check if this user has FireApp Installed
    private func isHasFireApp(phone: String) {
        showLoadingViewAlert()
        let formattedNumber = ContactsUtil.formatNumber(countryCode: UserDefaultsManager.getCountryCode(), number: phone)
        FireManager.isHasFireApp(phone: formattedNumber, appRealm: appRealm).subscribe(onNext: { (user) in
            self.hideLoadingViewAlert() {
                if let user = user {
                    self.navigationController?.popViewController(animated: true)
                    self.delegate?.segueToChatVC(user: user)
                    
                } else {
                    self.showAlert(type: .error, message: Strings.user_does_not_have_fireapp)
                }
            }
        }, onError: { (error) in
            self.hideLoadingViewAlert() {
                self.showAlert(type: .error, message: Strings.user_does_not_have_fireapp)
            }
            
        }).disposed(by: disposeBag)
    }
}


extension ChatViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        dismiss(animated: true, completion: nil)
    }
    
    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
}

extension ChatViewController: MTImagePickerControllerDelegate {
    
    
    // Implement it when setting source to MTImagePickerSource.Photos
    func imagePickerController(picker: MTImagePickerController, didFinishPickingWithPhotosModels models: [MTImagePickerPhotosModel]) {
        
        
        for model in models {
            
            //            //check if it's an image or a video
            if model.mediaType == .Photo {
                model.getImageAsyncData { data in
                    if let data = data {
                        self.sendImage(data: data, previewImage: model.getThumbImage(size: CGSize(width: 50, height: 50))!)
                    }
                    
                }
            } else {
                
                
                model.fetchAVPlayerItemAsync(complete: { (playerItem) in
                    if let video = playerItem {
                        DispatchQueue.main.async {
                            self.sendVideo(video: video, isFromCamera: false)
                        }
                        
                    }
                })
                
                
            }
            
        }
        
        
        
    }
    
    
    
    
    private func sendVoiceMessage(duration: CGFloat) {
        let message = MessageCreator(user: user, type: .SENT_VOICE_MESSAGE, appRealm: appRealm).quotedMessage(getQuotedMessage()).schedulingMode(bool: isInSchedulingMode).path(recorder.url.path).duration(duration.fromatSecondsFromTimer()).build()
        
        if isInSchedulingMode{
            sendScheduledMessage(message)
        }else{
            requestManager.request(message: message, callback: nil, appRealm: appRealm)
            
            FireManager.listenForSentVoiceMessagesState(receiverUid: user.uid, messageId: message.messageId, appRealm: appRealm).subscribe().disposed(by: disposeBag)
        }
        cancelReplyDidClick()
    }
    
}



extension ChatViewController: RecordViewDelegate {
    
    func onStart() {
        
        
        self.recorder.start()
        self.typingViewContainer.isHidden = true
        self.recordView.isHidden = false
        
        setTypingState(typingState: .RECORDING)
        
    }
    
    func onCancel() {
        
        recorder.stop()
        do {
            try recorder.url.deleteFile()
        } catch {
            
        }
        
        setTypingState(typingState: .NOT_TYPING)
        
    }
    
    func onFinished(duration: CGFloat) {
        recordView.isHidden = true
        typingViewContainer.isHidden = false
        
        recorder.stop()
        if duration < 1 {
            do {
                try recorder.url.deleteFile()
            } catch {
                
            }
        } else {
            sendVoiceMessage(duration: duration)
        }
        
        setTypingState(typingState: .NOT_TYPING)
    }
    
    func onAnimationEnd() {
        recordView.isHidden = true
        typingViewContainer.isHidden = false
        
    }
    
    
}


extension ChatViewController: ChooseActionAlertDelegate {
    fileprivate func sendLocation(_ mLocation: Location) {
        
        
        LocationImageExtractor.getMapImage(location: mLocation.location) { (mapImage) in
            guard let mapImage = mapImage else {
                return
            }
            
            let message = MessageCreator(user: self.user, type: .SENT_LOCATION, appRealm: appRealm).quotedMessage(self.getQuotedMessage()).location(mLocation.toRealmLocation(), mapImage: mapImage).schedulingMode(bool: self.isInSchedulingMode).build()
            
            if self.isInSchedulingMode {
                self.sendScheduledMessage(message)
            } else {
                
                self.uploadManager.sendMessage(message: message, callback: nil, appRealm: appRealm)
            }
            self.cancelReplyDidClick()
        }
        
        
        
    }
    
    func didClick(clickedItem: ClickedItem) {
        switch clickedItem {
        case .image:
            Permissions.requestPhotosPermissions { (isAuthorized) in
                if isAuthorized {
                    let imagePicker = ImagePickerRequest.getRequest(delegate: self)
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }
            
            break
            
        case .camera:
            Permissions.requestCameraPermissions { (isAuthorized) in
                if isAuthorized {
                    self.performSegue(withIdentifier: "toCamera", sender: nil)
                    
                }
            }
            break
            
        case .contact:
            
            Permissions.requestContactsPermissions { (isAuthorized) in
                if isAuthorized {
                    let contactPicker = ContactsPicker(delegate: self, multiSelection: true, subtitleCellType: .phoneNumber)
                    let navigationController = UINavigationController(rootViewController: contactPicker)
                    self.present(navigationController, animated: true, completion: nil)
                }
            }
            
            
            break
            
        case .location:
            let locationPicker = LocationPickerViewController()
            
            // button placed on right bottom corner
            locationPicker.showCurrentLocationButton = true // default: true
            
            // default: navigation bar's `barTintColor` or `.whiteColor()`
            locationPicker.currentLocationButtonBackground = .blue
            
            // ignored if initial location is given, shows that location instead
            locationPicker.showCurrentLocationInitially = true // default: true
            
            locationPicker.mapType = .standard // default: .Hybrid
            
            // for searching, see `MKLocalSearchRequest`'s `region` property
            locationPicker.useCurrentLocationAsHint = true // default: false
            
            // optional region distance to be used for creation region when user selects place from search results
            locationPicker.resultRegionDistance = 500 // default: 600
            
            locationPicker.completion = { location in
                
                // do some awesome stuff with location
                guard let mLocation = location else {
                    return
                }
                
                
                self.sendLocation(mLocation)
            }
            
            navigationController?.pushViewController(locationPicker, animated: true)
            
            break
            
        }
    }
}


extension ChatViewController: ContactsPickerDelegate {
    
    fileprivate func sendContacts(contacts: [Contact]) {
        
        for contact in contacts {
            if contact.phoneNumbers.isNotEmpty {
                let message = MessageCreator(user: self.user, type: .SENT_CONTACT, appRealm: appRealm).quotedMessage(self.getQuotedMessage()).schedulingMode(bool: isInSchedulingMode).contact(contact.toRealmContact()).build()
                
                if isInSchedulingMode{
                    sendScheduledMessage(message)
                }else{
                    uploadManager.sendMessage(message: message, callback: nil, appRealm: appRealm)
                }
            }
        }
        
        
        self.cancelReplyDidClick()
    }
    
    func contactPicker(_: ContactsPicker, didSelectMultipleContacts contacts: [Contact]) {
        dismiss(animated: true, completion: nil)
        if contacts.isEmpty {
            return
        }
        
        
        let alert = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "\(Strings.share) \(contacts.count) \(Strings.contacts)", style: .default, handler: { (_) in
            self.sendContacts(contacts:contacts)
        }))
        
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .default, handler: nil))
        
        self.present(alert, animated: true) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
            alert.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
        }
        
    }
    
    func contactPicker(_: ContactsPicker, didContactFetchFailed error: NSError) {
        
    }
    
    func contactPickerDidCancel(_: ContactsPicker) {
        dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: GrowingTextViewDelegate {
    
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        if let font = textView.font {
            let numLines = (textView.contentSize.height / font.lineHeight)
            if numLines > 1 {
                //if the visible row is the last row then scroll to bottom
                let shouldScroll = tblView.contentSize.height >= tblView.frame.height
                if tblView.lastVisibleRow == messages.lastIndex() && shouldScroll {
                    setContentOffset()
                }
            }
        }
        
        
        let text = textView.text.trim()
        
        
        if text.isEmpty {
            recordButton.animate(state: .toRecord)
            setTypingState(typingState: .NOT_TYPING)
            
        } else {
            recordButton.animate(state: .toSend)
            setTypingState(typingState: .TYPING)
            
        }
    }
}

var progress: Float = 0

extension ChatViewController: CellDelegate {
    
    func didClickQuotedMessage(at indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        if let quotedMessage = message.quotedMessage{
            if let quotedMessageStatus = quotedMessage.status, let status = realmHelper.getStatus(statusId: quotedMessageStatus.statusId), let user = realmHelper.getUser(uid: status.userId){
                
                
                let sender = ([status],user)
                
                performSegue(withIdentifier: "toViewStatus", sender: sender)
            }else{
                if let foundMessage = messages.filter({ $0.messageId == quotedMessage.messageId }).first, let index = messages.firstIndex(of: foundMessage) {
                    
                    scrollAndHighlightQuotedMessage(index)
                }
            }
        }
        
        
    }
    
    func didSelectItem(at indexPath: IndexPath) {
        let message = messages[indexPath.row]
        selectOrDeselectItem(indexPath: indexPath, message: message)
    }
    
    
    func didClickCell(indexPath: IndexPath?) {
        
        guard let index = indexPath, let message = messages?.getItemSafely(index: index.row) as? Message else {
            return
        }
        
        if isInSelectMode {
            selectOrDeselectItem(indexPath: index, message: message)
            return
        }
        
        
        switch message.typeEnum {
            
        case .SENT_IMAGE, .RECEIVED_IMAGE:
            
            if message.typeEnum == .RECEIVED_IMAGE && message.localPath == "" {
                return
            }
            
            if !FileUtil.exists(at: message.localPath) {
                showAlert(type: .error, message: Strings.file_not_exists)
                return
            }
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "PreviewImageController") as! PreviewImageVideoViewController
            
            
            newViewController.initialize(chatId: user.uid, user: user, messageId: message.messageId)
            navigationController?.pushViewController(newViewController, animated: true)
            break
            
        case .SENT_VIDEO, .RECEIVED_VIDEO:
            
            if message.typeEnum == .RECEIVED_VIDEO && message.localPath == "" {
                return
            }
            
            if !FileUtil.exists(at: message.localPath) {
                showAlert(type: .error, message: Strings.file_not_exists)
                return
            }
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "PreviewImageController") as! PreviewImageVideoViewController
            
            
            newViewController.initialize(chatId: user.uid, user: user, messageId: message.messageId)
            
            navigationController?.pushViewController(newViewController, animated: true)
            
            break
            
            
        case .SENT_CONTACT, .RECEIVED_CONTACT:
            if let contact = message.contact {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let newViewController = storyBoard.instantiateViewController(withIdentifier: "ViewContactDetailsVC") as! ViewContactDetailsVC
                
                navigationController?.pushViewController(newViewController, animated: true)
                newViewController.initialize(contact: contact)
            }
            
            break
            
            
            
            
        case .SENT_LOCATION, .RECEIVED_LOCATION:
            
            guard let location = message.location else {
                return
            }
            
            let controller = ViewLocationVC()
            controller.initialize(location: location)
            navigationController?.pushViewController(controller, animated: true)
            
            break
            
        case .SENT_FILE, .RECEIVED_FILE:
            currentFilePath = message.localPath
            let ql = QLPreviewController()
            ql.dataSource = self
            present(ql, animated: true, completion: nil)
            
            break
            
            
        default:
            
            break
            
        }
    }
    
    func didLongClickCell(indexPath: IndexPath?, view: UIView?) {
        if isInSelectMode {
            return
        }
        
        guard let indexPath = indexPath, let view = view, let message = messages.getItemSafely(index: indexPath.row) as? Message else {
            return
        }
        
        
        let contextVC = ContextMenuViewController()
        //clicked item
        contextVC.currentIndexPath = indexPath
        contextVC.delegate = self
        switch message.typeEnum {
        case .SENT_TEXT, .RECEIVED_TEXT:
            
            break
            
        case .SENT_CONTACT, .RECEIVED_CONTACT, .SENT_LOCATION, .RECEIVED_LOCATION:
            //ADD FORWARD ITEM
            contextVC.removeItems(items: [.copy])
        default:
            
            //ADD FORWARD
            if !canForwardOrShare(message: message) {
                contextVC.removeItems(items: [.copy, .forward])
            } else {
                contextVC.removeItems(items: [.copy])
            }
            
        }
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: contextVC,
            options: ContextMenu.Options(
                containerStyle: ContextMenu.ContainerStyle(
                    backgroundColor: UIColor(red: 41 / 255.0, green: 45 / 255.0, blue: 53 / 255.0, alpha: 1)
                    
                ),
                menuStyle: .minimal,
                hapticsStyle: .light
            ), sourceView: view
        )
    }
    
    
    func didClickProgressBtn(indexPath: IndexPath) {
        guard let message = messages?.getItemSafely(index: indexPath.row) as? Message else {
            return
        }
        
        if message.downloadUploadState == .LOADING {
            if message.typeEnum.isSentType() {
                UploadManager.cancelUpload(message: message, appRealm: appRealm)
            } else {
                RequestManager.cancelDownload(message: message, appRealm: appRealm)
            }
        } else if message.downloadUploadState == .CANCELLED || message.downloadUploadState == .FAILED {
            
            requestManager.request(message: message, callback: nil, appRealm: appRealm)
            
        }
        
        
    }
    
}

extension ChatViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let url = URL(fileURLWithPath: currentFilePath)
        return url as! QLPreviewItem
    }
    
}


extension ChatViewController: ContextMenuSelectDelegate {
    fileprivate func showReplyLayout(_ message: Message, _ indexPath: IndexPath) {
        let type = message.typeEnum
        
        replyLayout.isHidden = false
        replyLayoutBottomConstraint.constant = 0
        replyUserName.text = Strings.you
        replyDescTitle.text = MessageTypeHelper.getMessageContent(message: message, includeEmoji: false)
        replyIcon.isHidden = type.isText() ||  type.isStickerType()
        replyThumb.isHidden = !type.isImage() && !type.isVideo() && !type.isStickerType()
        
        if type.isStickerType() && message.localPath != ""{
            replyThumb.image = UIImage(named: message.localPath)
        }
        else if type.isImage() {
            replyThumb.image = message.thumb.toUIImage()
        }
        else if type.isVideo() {
            replyThumb.image = message.videoThumb.toUIImage()
        }
        
        replyIcon.image = UIImage(named: MessageTypeHelper.getMessageTypeImage(type: type))
        
        tblView.translatesAutoresizingMaskIntoConstraints = false
        tblView.bottomAnchor.constraint(equalTo: replyLayout.topAnchor, constant: -16).isActive = true
        
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        })
        textView.becomeFirstResponder()
        currentQuotedMessage = messages[indexPath.row]
        
    }
    
    func didSelect(itemType: ContextItemType, indexPath: IndexPath) {
        
        guard let message = messages?[indexPath.row] else {
            return
        }
        
        switch itemType {
        case .forward, .delete:
            contextSelectedItemType = itemType
            isInSelectMode = true
            selectOrDeselectItem(indexPath: indexPath, message: message)
            
        case .copy:
            UIPasteboard.general.string = message.content
            
        case .reply:
            showReplyLayout(message, indexPath)
            break
            
        }
        
        
    }
}

extension ChatViewController: UserDetailsDelegate {
    func didClickSearch() {
        
        //enter search mode
        //we're adding delay to wait for this view to be layout after getting back from the other vc
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.setupNavigationItems(true)
        }
        
    }
    
    func didClickScheduleMessage(date:Date) {
        //enter search mode
        //we're adding delay to wait for this view to be layout after getting back from the other vc
        isInSchedulingMode = true
        schedulingDate = date
    }
}

extension ChatViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        
        // Remove focus from the search bar.
        //        searchBar.endEditing(true)
        
        searchBar.resignFirstResponder()
        
        tblView.reloadData()
        setupNavigationItems()
        
        
    }
    
    
    
    //this will scroll to found message when searching
    //after scrolling it will highlight the message
    fileprivate func scrollAndHighlightSearch(_ index: Int) {
        guard let message = messages.getItemSafely(index: index) as? Message else {
            return
        }
        
        
        DispatchQueue.main.async {
            let numberOfRows = self.tblView.numberOfRows(inSection: 0)
            
            if numberOfRows > 0 {
                
                let indexPath = IndexPath(row: index, section: 0)
                self.tblView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    let cell = self.tblView.cellForRow(at: IndexPath(row: index, section: 0))
                    
                    if let cell = cell as? SentTextCell {
                        cell.messageText.highlightText(text: message.content)
                    } else if let cell = cell as? ReceivedTextCell {
                        cell.textView.highlightText(text: message.content)
                    }
                })
            }
        }
    }
    
    //this will scroll to quoted message
    //after scrolling it will highlight the message
    fileprivate func scrollAndHighlightQuotedMessage(_ index: Int) {
        guard let message = messages.getItemSafely(index: index) as? Message else {
            return
        }
        
        
        
        DispatchQueue.main.async {
            let numberOfRows = self.tblView.numberOfRows(inSection: 0)
            
            if numberOfRows > 0 {
                
                let indexPath = IndexPath(row: index, section: 0)
                self.tblView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    let cell = self.tblView.cellForRow(at: IndexPath(row: index, section: 0))
                    
                    if let cell = cell as? BaseCell {
                        let currentColor = cell.containerView.backgroundColor
                        UIView.animate(withDuration: 0.4, delay: 0.0, options: [.curveEaseOut], animations: {
                            cell.containerView.backgroundColor = .darkGray
                        }, completion: { (bool) in
                            cell.containerView.backgroundColor = currentColor
                        })
                    }
                })
                
            }
        }
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchResults = realmHelper.searchForMessage(chatId: user.uid, query: searchBar.text!)
        if !searchResults.isEmpty {
            searchIndex = searchResults.count - 1
            let foundMessageId = searchResults[searchIndex].messageId
            
            let index = messages.getIndexById(messageId: foundMessageId)
            if let index = index {
                
                scrollAndHighlightSearch(index)
                disableOrEnableArrows()
            }
            
            
        }
        
    }
    
    
    
    
}


extension ChatViewController: UIScrollViewDelegate {
    
    //hide or show scrollToBottom button depending on scrolling state
    
    func hideUnreadCount() {
        self.unReadCount = 0
        unreadMessagesLbl.text = ""
        unreadMessagesLbl.isHidden = true
    }
    
    fileprivate func hideOrShowScrollDownView() {
        
        if messages.isEmpty {
            return
        }
        
        
        
        if tblView.lastVisibleRow != messages.lastIndex() {
            if scrollDownView.isHidden {
                hideWithAnimation(false)
            }
        } else {
            hideWithAnimation(true)
            hideUnreadCount()
        }
    }
    
    func hideWithAnimation(_ isHidden: Bool) {
        let alpha: CGFloat = isHidden ? 0 : 1.0
        
        if !isHidden {
            self.scrollDownView.isHidden = isHidden
            UIView.animate(withDuration: 0.2, animations: {
                self.scrollDownView.alpha = alpha
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.scrollDownView.alpha = alpha
            }) { (_) in
                self.scrollDownView.isHidden = isHidden
                
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            
            hideOrShowScrollDownView()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        hideOrShowScrollDownView()
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        hideOrShowScrollDownView()
    }
    
    
}
//check which user is typing,recording
extension ChatViewController: GroupTypingDelegate {
    func onTyping(state: TypingState, groupId: String, user: User?) {
        if let user = user {
            let name = user.userName
            typingStateLbl.text = name + " \(Strings.is) " + state.getStatString()
        }
        
    }
    
    func onAllNotTyping(groupId: String) {
        setMembersInToolbar()
    }
    
    //set group members names in toolbar and separate them by ","
    private func setMembersInToolbar() {
        var names = ""
        let SEPARATOR = " , "
        
        
        let users = user.isGroupBool ? user.group!.users : user.broadcast!.users
        
        for user in users {
            if user.uid == FireManager.getUid() {
                names += Strings.you + SEPARATOR
            } else {
                names += user.userName + SEPARATOR
            }
        }
        
        let userNames = StringUtils.removeExtraSeparators(text: names, separator: SEPARATOR)
        
        typingStateLbl.text = userNames
        
        
    }
}

extension ChatViewController: ProximitySensorDelegate {
    func didChange(near: Bool) {
        let speakerType: SpeakerType = near ? .earpiece : .speaker
        audioPlayer.speakerType = speakerType
        
    }
}
extension ChatViewController: CameraResult {
    
    
    
    //this is called when user takes a video from the Camera
    func videoTaken(videoUrl: URL) {
        let playerItem = AVPlayerItem(asset: AVAsset(url: videoUrl))
        sendVideo(video: playerItem, isFromCamera: true)
    }
    //this is called when user takes a photo from the Camera
    func imageTaken(image: UIImage?) {
        if let image = image, let data = image.toData(.highest) {
            sendImage(data: data)
        }
    }
}


extension ChatViewController:StickerProviderDelegate{
    func willLoadSticker(imageView: UIImageView, sticker: Sticker) {

        if sticker.resourceType == .assets {
            let stickerData = sticker.data
            let stickerImage = UIImage(named: stickerData)
            imageView.image = stickerImage
        }
    }
    
    func willLoadStickerCategory(imageView: UIImageView, stickerCategory: StickerCategory, selected: Bool) {
        if stickerCategory.iconResourceType == .assets {
            let icon = stickerCategory.icon
            imageView.image = UIImage(named: icon)
        }
    }
    
    func didChangePage(category: StickerCategory) {
        
    }
    
    func didClickSticker(sticker: Sticker) {
        sendSticker(stickerPath: sticker.data)
    }
}

//guard let navigationController = self.navigationController else { return }
//var navigationArray = navigationController.viewControllers
//navigationArray.remove(at: navigationArray.count - 1)
//self.navigationController?.viewControllers = navigationArray
