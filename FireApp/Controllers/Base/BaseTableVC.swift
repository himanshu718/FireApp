//
//  BaseTableVC.swift
//  FireApp
//
//  Created by Devlomi on 12/3/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import SwiftEventBus
import NotificationView

class BaseTableVC: UITableViewController, Base {
    lazy var notificationDelegate: NotificationViewDelegate = self


    var disposeBag = DisposeBag()
    private var loadingAlertView: UIAlertController?


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleNewMessageNotification()
        handleNotificationTap()
        handleGroupLinkTap()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SwiftEventBus.unregister(self, name: EventNames.newMessageReceived)
        SwiftEventBus.unregister(self, name: EventNames.notificationTapped)
        SwiftEventBus.unregister(self, name: EventNames.groupLinkTapped)
    }
    deinit {
        SwiftEventBus.unregister(self)
    }
    
    func unRegisterEvents() {
        handleUnRegisterEvents()
    }
    
    func showLoadingViewAlert() {
        loadingAlertView = loadingAlert()
        self.present(loadingAlertView!, animated: true)

    }

    func hideLoadingViewAlert(_ completion: (() -> Void)? = nil) {
        loadingAlertView?.dismiss(animated: true, completion: completion)
    }
}
extension BaseTableVC: NotificationViewDelegate {
    func notificationViewDidTap(_ notificationView: NotificationView) {
        swizzledNotificationViewDidTap(notificationView)
    }

}

