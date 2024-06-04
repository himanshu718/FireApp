//
//  Base.swift
//  FireApp
//
//  Created by Devlomi on 1/2/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import NotificationView
protocol Base {
    var disposeBag:DisposeBag { get }
    func handleNewMessageNotification()
    func handleNotificationTap()
    var notificationDelegate:NotificationViewDelegate { get set }
    func unRegisterEvents()

}
