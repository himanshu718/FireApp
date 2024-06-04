//
//  ChatsListVC.swift
//  FireApp
//
//  Created by Devlomi on 9/18/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import GoogleMobileAds
import Contacts
import NotificationBannerSwift
import NotificationView


protocol ChatCountDelegate: AnyObject {
    func refreshCount()
}

class ChatsListVC: BaseSearchableVC {
    
    //MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var searchBarTopAnchor: NSLayoutConstraint!
    
    var objPushFromAction = 0
    var unreadCountsSum: Int = 0
    var searchController: UISearchController!
    private var isInSearchMode = false
    
    private var currentTypingUsersDict = [String: TypingState]()
    
    weak var delegate: ChatCountDelegate?
    
    var chats: Results<Chat>!
    var searchResults: Results<Chat>!
    override var enableAds: Bool {
        get {
            return Config.isChatsAdsEnabled
        }
        set { }
    }
    
    override var adUnitAd: String {
        get {
            return Config.mainViewAdsUnitId
        }
        set { }
    }
    
    var notificationToken: NotificationToken?
    
    fileprivate func listenForTypingState() {
        for chat in chats {
            if let user = chat.user {
                if user.isGroupBool && user.group?.isActive ?? false {
                    _ = GroupTyping(groupId: user.uid, users: user.group!.users, disposeBag: disposeBag, delegate: self)
                } else if !user.isBroadcastBool {
                    
                    FireManager.listenForTypingState(uid: user.uid).subscribe(onNext: { (state) in
                        self.updateChatLastMessageOrStateLbl(uid: user.uid, state: state)
                        
                    }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
                }
            }
        }
    }
    
    fileprivate func attachListeners() {
        listenForTypingState()
        addMessageStateListener()
        addVoiceMessageStateListener()
    }
    
    fileprivate func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchBarContainer.addSubview(searchController.searchBar)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if objPushFromAction == 1{
            searchBarTopAnchor.constant = 0
        }
        
        self.chats = RealmHelper.getInstance(appRealm).getChats().filter("chatId != ''")
        
        self.searchResults = self.chats
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        setNavbar()
        
        setupSearchController()
        notificationToken = chats?.observe { [weak self] (changes: RealmCollectionChange) in
            guard let strongSelf = self else { return }
            changes.updateTableView(tableView: strongSelf.tableView)
        }
        
        if RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid()) == nil {
            let user = User()
            user.uid = FireManager.getUid()
            RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user)
        }
        UserDefaultsManager.setFetchingUnDeliveredMessages(bool: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Chats"
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(hexString: "#2196f5")
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func goToChatVC(user: User) {
        performSegue(withIdentifier: "toChatVC", sender: user)
    }
    
    private func addMessageStateListener() {
        for chat in chats {
            
            if let lastMessage = chat.lastMessage, let user = chat.user {
                
                if !user.isBroadcastBool && lastMessage.typeEnum != .GROUP_EVENT && lastMessage.messageState != .READ {
                    
                    let reference = FireConstants.messageStat.child(chat.chatId).child(lastMessage.messageId)
                    reference.rx.observeEvent(.value).subscribe(onNext: { (snapshot) in
                        
                        guard let intState = snapshot.value as? Int, let state = MessageState(rawValue: intState)else {
                            return
                        }
                        
                        let key = snapshot.key
                        let chatId = chat.chatId
                        RealmHelper.getInstance(appRealm).updateMessageStateLocally(messageId: key, chatId: chatId, messageState: state)
                        
                    }).disposed(by: disposeBag)
                    
                }
            }
        }
    }
    
    
    
    private func addVoiceMessageStateListener() {
        for chat in chats {
            if let lastMessage = chat.lastMessage, let user = chat.user {
                
                if !user.isBroadcastBool && lastMessage.typeEnum != .GROUP_EVENT && lastMessage.isVoiceMessage() && lastMessage.fromId == FireManager.getUid() && !lastMessage.voiceMessageSeen {
                    FireManager.listenForSentVoiceMessagesState(receiverUid: chat.chatId, messageId: lastMessage.messageId, appRealm: appRealm).subscribe().disposed(by: disposeBag)
                }
            }
        }
    }
    
    fileprivate func setLastMessageText(_ state: TypingState, _ chat: Chat, _ cell: ChatCell) {
        if state == .NOT_TYPING {
            if let message = chat.lastMessage {
                if message.typeEnum == .GROUP_EVENT, let user = chat.user, let group = user.group {
                    cell.lastMessage.text = GroupEvent.extractString(messageContent: message.content, users: group.users)
                } else {
                    cell.lastMessage.text = MessageTypeHelper.getMessageContent(message: message, includeEmoji: false)
                }
            } else {
                
                cell.lastMessage.text = ""
                
            }
            
            cell.lastMessage.textColor = Colors.notTypingColor
            
        } else {
            cell.lastMessage.textColor = Colors.typingAndRecordingColors
            cell.lastMessage.text = state.getStatString()
        }
        
    }
    
    private func updateChatLastMessageOrStateLbl(uid: String, state: TypingState, userInGroupTyping: User? = nil) {
        
        currentTypingUsersDict[uid] = state
        
        if isInSearchMode {
            return
        }
        
        guard let index = chats.getIndexById(chatId: uid), let chat = chats.getItemSafely(index: index) as? Chat else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        if let cell = tableView.cellForRow(at: indexPath) as? ChatCell {
            if let user = userInGroupTyping {
                cell.lastMessage.text = user.userName + Strings.is + state.getStatString()
                cell.lastMessage.textColor = Colors.typingAndRecordingColors
                
            } else {
                setLastMessageText(state, chat, cell)
            }
        }
        
    }
    @objc private func rightBarBtnTapped() {
        if let tabBarController = tabBarController as? TabBarVC {
            tabBarController.goToUsersVC()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ChatViewController, let user = (sender) as? User {
            controller.initialize(user: user)
            controller.delegate = self
        }
        
        else if let controller = segue.destination as? UserDetailsBase, let user = (sender as? Chat)?.user {
            controller.initialize(user: user)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(rightBarBtnTapped))
        tabBarController?.navigationItem.title = Strings.chats
        
        self.attachListeners()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tabBarController?.navigationItem.rightBarButtonItem = nil
    }
    
    //hide title ('back button') when going to ChatVC
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController?.navigationItem.title = " "
        
        if searchController.isActive {
            isInSearchMode = false
            searchController.isActive = false
        }
    }
    
    deinit {
        notificationToken = nil
    }
    func setNavbar(){
        if #available(iOS 13.0, *) {
            // Create a custom navigation bar appearance for iOS 13 and later
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = UIColor.init(hexString: "#2196f5")
            navigationBarAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            navigationController?.navigationBar.standardAppearance = navigationBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        } else {
            // For iOS versions prior to 13
            navigationController?.navigationBar.barTintColor = UIColor.init(hexString: "#2196f5")
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
}

extension ChatsListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getDataSource().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell") as? ChatCell, let chat = getDataSource().getItemSafely(index: indexPath.row) as? Chat {
            
            cell.bind(chat: chat)
            
            //save state on scroll
            if let typingState = currentTypingUsersDict[chat.chatId] {
                setLastMessageText(typingState, chat, cell)
            }
            
            if let user = chat.user {
                FireManager.checkAndDownloadUserThumb(user: user, appRealm: appRealm).subscribe().disposed(by: disposeBag)
            }
            
            unreadCountsSum = getDataSource().reduce(0) { $0 + $1.unReadCount }
            print("unreadCountsSum\(unreadCountsSum)")
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let chat = getDataSource().getItemSafely(index: indexPath.row) as? Chat
        if chat?.user?.isGroupBool != false{
            return 60.0
        }
        return 0.0
    }
    
    fileprivate func exitSearchModeExplicitly() {
        isInSearchMode = false
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let chat = getDataSource().getItemSafely(index: indexPath.row) as? Chat, let user = chat.user else { return }
        print(user)
        if user.isGroupBool != false{
            exitSearchModeExplicitly()
            RealmHelper.getInstance().deleteUnReadMessages(chatId: chat.chatId)
            goToChatVC(user: user)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.delegate?.refreshCount()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let chat = self.getDataSource().getItemSafely(index: indexPath.row) as? Chat, let user = chat.user else {
            return nil
        }
        let moreAction = UIContextualAction(style: .normal, title: Strings.more) { (_, _, actionPerformed) in
            let alert = self.properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
            let mute = chat.isMuted ? Strings.unMute : Strings.mute
            
            let muteAction = UIAlertAction(title: mute, style: .default, handler: { (_) in
                actionPerformed(true)
                RealmHelper.getInstance(appRealm).setChatMuted(chatId: chat.chatId, isMuted: !chat.isMuted)
            })
            
            let clearChatAction = UIAlertAction(title: Strings.clearChat, style: .default, handler: { (_) in

                let confirmationAlert = self.properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
                let deleteAction = UIAlertAction(title: Strings.deleteMessages, style: .destructive, handler: { (_) in
                    actionPerformed(true)
                    RealmHelper.getInstance(appRealm).clearChat(chatId: chat.chatId).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).subscribe().disposed(by: self.disposeBag)
                })
                let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
                
                
                confirmationAlert.addAction(deleteAction)
                confirmationAlert.addAction(cancelAction)
                
                self.present(confirmationAlert, animated: true, completion: nil)
                
            })
            
            let exitGroupAction = UIAlertAction(title: Strings.exit_group, style: .destructive, handler: { (_)in
                
                let exitGroupAlert = self.properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
                
                let exitGroupAction = UIAlertAction(title: Strings.exit_group, style: .destructive, handler: { (_)in
                    self.showLoadingViewAlert()
                    self.exitGroup(groupId: user.uid)
                })
                
                exitGroupAlert.addAction(cancelAction)
                exitGroupAlert.addAction(exitGroupAction)
                self.present(exitGroupAlert, animated: true, completion: nil)
                
            })
            
            let deleteChatAction = UIAlertAction(title: Strings.deleteChat, style: .destructive, handler: { (_) in
                
                let confirmationAlert = self.properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
                let deleteAction = UIAlertAction(title: Strings.delete, style: .destructive, handler: { (_) in
                    actionPerformed(true)
                    
                    self.showLoadingViewAlert()
                    
                    if user.isBroadcastBool {
                        self.deleteBroadcast(broadcastId: user.uid)
                        tableView.reloadData()
                    } else {
                        RealmHelper.getInstance(appRealm).deleteChat(chatId: chat.chatId).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).subscribe().disposed(by: self.disposeBag)
                        tableView.reloadData()
                        self.hideLoadingViewAlert()
                        
                    }
                    
                })
                let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
                
                confirmationAlert.addAction(deleteAction)
                confirmationAlert.addAction(cancelAction)
                
                self.present(confirmationAlert, animated: true, completion: nil)
                
            })
            
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
            
            alert.addAction(muteAction)
            alert.addAction(clearChatAction)
            if user.isGroupBool && user.group!.isActive {
                alert.addAction(exitGroupAction)
            } else {
                alert.addAction(deleteChatAction)
            }
            
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        let infoAction = UIContextualAction(style: .normal, title: Strings.info) { (_, _, actionPerformed) in
            actionPerformed(true)
            if let user = chat.user {
                let segueIdentifier = user.isGroupBool ? "toGroupDetails" : "toUserDetails"
                self.exitSearchModeExplicitly()
                self.performSegue(withIdentifier: segueIdentifier, sender: chat)
            }
        }
        
        let resizedSize = CGSize(width: 24, height: 24)
        moreAction.backgroundColor = .blue
        infoAction.image = UIImage(named: "info")?.tinted(with: .white)?.resized(to: resizedSize)
        moreAction.image = UIImage(named: "more")?.tinted(with: .white)?.resized(to: resizedSize)
        return UISwipeActionsConfiguration(actions: [moreAction, infoAction])
    }
    
    private func getDataSource() -> Results<Chat> {
        return isInSearchMode ? searchResults : chats
    }
    
    private func deleteBroadcast(broadcastId: String) {
        BroadcastManager.deleteBroadcast(broadcastId: broadcastId).subscribe(onCompleted: {
            self.hideLoadingViewAlert()
        }, onError: { (error) in
            self.hideLoadingViewAlert()
        }).disposed(by: self.disposeBag)
    }
    
    private func exitGroup(groupId: String) {
        GroupManager.exitGroup(groupId: groupId).subscribe(onError: { (error) in
            self.hideLoadingViewAlert()
        }, onCompleted: {
            self.hideLoadingViewAlert()
        }).disposed(by: self.disposeBag)
    }
    
}

extension ChatsListVC: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isInSearchMode = false
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResults = RealmHelper.getInstance(appRealm).searchForChat(query: searchText)
        
        isInSearchMode = searchText.isNotEmpty
        tableView.reloadData()
        
    }
}
extension ChatsListVC: GroupTypingDelegate {
    
    func onAllNotTyping(groupId: String) {
        currentTypingUsersDict.removeValue(forKey: groupId)
        updateChatLastMessageOrStateLbl(uid: groupId, state: .NOT_TYPING)
    }
    
    func onTyping(state: TypingState, groupId: String, user: User?) {
        guard let user = user else {
            return
        }
        currentTypingUsersDict[groupId] = state
        updateChatLastMessageOrStateLbl(uid: groupId, state: state, userInGroupTyping: user)
    }
}

extension ChatsListVC: ChatVCDelegate {
    func segueToChatVC(user: User) {
        //wait for navigation bar to be ready.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.goToChatVC(user: user)
        }
    }
}
