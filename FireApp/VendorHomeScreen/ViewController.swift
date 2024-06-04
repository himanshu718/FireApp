//
//  ViewController.swift
//  FireApp
//
//  Created by iMac on 27/10/23.
//  Copyright © 2023 Devlomi. All rights reserved.
//

import UIKit
import DropDown

class ViewController: UIViewController,ChatCountDelegate,NotificationBadgeDelegate {
    func refreshBadge() {
        setupBadge()
    }
    
    
    var user: User!
    let btnVendorMore = UIButton.init(type: .custom)
    var unrNotificationCount: Int = 0
    weak var delegate: ChatCountDelegate?
    let dropDown = DropDown()
    var btnChat = UIButton.init(type: .custom)
    var notificationLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBadge()
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
        let title = UILabel()
        title.text = "Gofernets"
        title.textColor = .white
        title.font = .preferredFont(forTextStyle: .headline)
        
        btnVendorMore.setImage(UIImage(named: "more"), for: .normal)
        btnVendorMore.tintColor = .white
        btnVendorMore.addTarget(self, action: #selector(ViewController.btnMoreAction), for: .touchUpInside)
        btnVendorMore.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        btnChat = UIButton.init(type: .custom)
        btnChat.setImage(UIImage(named: "chat"), for: .normal)
        btnChat.tintColor = .white
        btnChat.addTarget(self, action: #selector(ViewController.btnChatAction), for: .touchUpInside)
        btnChat.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        
        if #available(iOS 13.0, *) {
            if user?.userType.lowercased() == "operator" {
                let tc = OperatorTabPageViewController()
                tc.navigationItem.hidesBackButton = true
                
//                let btnCall = UIButton.init(type: .custom)
//                btnCall.setImage(UIImage(named: "call-1"), for: .normal)
//                btnCall.tintColor = .white
//                btnCall.addTarget(self, action: #selector(ViewController.btnCallAction), for: .touchUpInside)
//                btnCall.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                
                
                let btnWallet = UIButton.init(type: .custom)
                btnWallet.setImage(UIImage(named: "wallet"), for: .normal)
                btnWallet.tintColor = .white
                btnWallet.addTarget(self, action: #selector(ViewController.btnWalletAction), for: .touchUpInside)
                btnWallet.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                
                let btnChat = UIButton.init(type: .custom)
                btnChat.setImage(UIImage(named: "chat"), for: .normal)
                btnChat.tintColor = .white
                btnChat.addTarget(self, action: #selector(ViewController.btnChatAction), for: .touchUpInside)
                btnChat.frame = CGRect(x: 0, y: 0, width: 36, height: 36)

                notificationLabel = UILabel()
                notificationLabel.textColor = .white
                notificationLabel.textAlignment = .center
                notificationLabel.font = UIFont.boldSystemFont(ofSize: 9)
                notificationLabel.frame = CGRect(x: 23, y: 0, width: 12, height: 12)
                notificationLabel.layer.cornerRadius = 6
                notificationLabel.layer.masksToBounds = true
                notificationLabel.backgroundColor = .red
                
                notificationLabel.text = "\(unrNotificationCount)"
                if unrNotificationCount > 0 {
                    notificationLabel.sizeToFit() // Adjust the size of the label to fit its content
                    let labelWidth = notificationLabel.frame.width + 6 // Add some padding to the calculated width
                    notificationLabel.frame = CGRect(x: 23, y: 0, width: labelWidth, height: 12)
                    btnChat.addSubview(notificationLabel)
                }
                
                let barbtnMore = UIBarButtonItem(customView: btnVendorMore)
//                let barbtnCall = UIBarButtonItem(customView: btnCall)
                let barbtnWallet = UIBarButtonItem(customView: btnWallet)
                let barbtnChat = UIBarButtonItem(customView: btnChat)
                let barTitle = UIBarButtonItem(customView: title)
                
                tc.navigationItem.leftBarButtonItem = barTitle
                tc.navigationItem.setRightBarButtonItems([barbtnMore, barbtnWallet, barbtnChat], animated: true)

                navigationController?.pushViewController(tc, animated: true)
            }else{
                let tc = VendorTabPageViewController()
                tc.navigationItem.hidesBackButton = true
                
                notificationLabel = UILabel()
                notificationLabel.textColor = .white
                notificationLabel.textAlignment = .center
                notificationLabel.font = UIFont.boldSystemFont(ofSize: 9)
                notificationLabel.frame = CGRect(x: 23, y: 0, width: 12, height: 12)
                notificationLabel.layer.cornerRadius = 6
                notificationLabel.layer.masksToBounds = true
                notificationLabel.backgroundColor = .red
                
                notificationLabel.text = "\(unrNotificationCount)"
                if unrNotificationCount > 0 {
                    notificationLabel.sizeToFit() // Adjust the size of the label to fit its content
                    let labelWidth = notificationLabel.frame.width + 6 // Add some padding to the calculated width
                    notificationLabel.frame = CGRect(x: 23, y: 0, width: labelWidth, height: 12)
                    btnChat.addSubview(notificationLabel)
                }
                
                
                let barbtnMore = UIBarButtonItem(customView: btnVendorMore)
                let barbtnChat = UIBarButtonItem(customView: btnChat)
                let barTitle = UIBarButtonItem(customView: title)
                
                tc.navigationItem.leftBarButtonItem = barTitle
                tc.navigationItem.setRightBarButtonItems([barbtnMore, barbtnChat], animated: true)

                navigationController?.pushViewController(tc, animated: true)
            }
        }
        
        notificationBadgeDelegate = self
    }
    
    
    private func setupBadge() {
        let unreadChats = RealmHelper.getInstance().getUnreadChats()
        unrNotificationCount = 0
        if unreadChats.count == 0 {
            notificationLabel.text = "\(unrNotificationCount)"
            notificationLabel.isHidden = true
        } else{
            for chat in unreadChats {
                print("unread chatcount  \(chat.unReadCount)")
                print("unread chat \(chat)")
                unrNotificationCount += chat.unReadCount
            }
            print(" My Unread count \(unrNotificationCount)")
            notificationLabel.text = "\(unrNotificationCount)"
            notificationLabel.isHidden = false
        }
    }

    
    @objc func btnCallAction() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "CallsVC") as! CallsVC
        vc.objPushFromAction = 1
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc func btnWalletAction() {
        let storyboard = UIStoryboard(name: "Payment", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PaymentViewController") as! PaymentViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func btnMoreAction() {
        dropDown.dataSource = ["Share App", "Become a operator", "Settings"]
        dropDown.anchorView = btnVendorMore
        dropDown.bottomOffset = CGPoint(x: 0, y: btnVendorMore.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let _ = self else { return }
            
            if item == "Settings"{
                self!.goToSettingsVC()
            } else if item == "Share App" {
                if let urlStr = NSURL(string: "https://apps.apple.com/ng/app/gofernets-pickup-delivery/id6475963976") {
                    let objectsToShare = [urlStr]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        if let popup = activityVC.popoverPresentationController {
                            popup.sourceView = self!.view
                            popup.sourceRect = CGRect(x: self!.view.frame.size.width / 2, y: self!.view.frame.size.height / 4, width: 0, height: 0)
                        }
                    }

                    self!.present(activityVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func btnChatAction() {
        self.goToChatVC(user: user)
    }
    

    func goToChatVC(user: User) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatsListVC") as! ChatsListVC
        vc.objPushFromAction = 1
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func goToSettingsVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "settingsVC") as! SettingsVC
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func refreshCount() {
        setupBadge()
    }
}
