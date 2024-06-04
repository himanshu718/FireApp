//
//  BaseVC.swift
//  FireApp
//
//  Created by Devlomi on 10/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import NotificationView
import SwiftEventBus

class BaseVC: UIViewController, Base {
    lazy var notificationDelegate: NotificationViewDelegate = self

    var disposeBag = DisposeBag()


    private var loadingAlertView: UIAlertController?

    open var enablePresence = false
    open var listenForKeyboard = false {
        didSet {
            if listenForKeyboard {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keyBoardWillShow),
                    name: UIResponder.keyboardWillShowNotification,
                    object: nil
                )

                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keyBoardWillHide(notification:)),
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )

            } else {
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationView = NotificationView.default
        notificationView.hide()
        
        SwiftEventBus.onMainThread(self, name: EventNames.logout) { _ in
            self.disposeBag = DisposeBag()
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleNewMessageNotification()
        handleNotificationTap()
        handleGroupLinkTap()
    }



    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //hide title ('back button') when going to ChatVC
//        tabBarController?.navigationItem.title = " "

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SwiftEventBus.unregister(self, name: EventNames.newMessageReceived)
        SwiftEventBus.unregister(self, name: EventNames.notificationTapped)
        SwiftEventBus.unregister(self, name: EventNames.groupLinkTapped)


    }



    func keyboardWillShow(keyboardFrame: CGRect?) {

    }

    func keyBoardWillHide() {


    }

    func showLoadingViewAlert() {
        loadingAlertView = loadingAlert()
        self.present(loadingAlertView!, animated: true)

    }

    func hideLoadingViewAlert(_ completion: (() -> Void)? = nil) {
        loadingAlertView?.dismiss(animated: true, completion: completion)
    }

    func unRegisterEvents() {
        handleUnRegisterEvents()
    }
    @objc private func keyBoardWillShow(notification: NSNotification) {



        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue



            keyboardWillShow(keyboardFrame: keyboardRectangle)


        }
    }


    @objc private func keyBoardWillHide(notification: NSNotification) {
        keyBoardWillHide()

    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        SwiftEventBus.unregister(self)
    }


    func makeACall(user: User, callType:CallType) {

        showLoadingViewAlert()

        FireManager.isUserBlocked(otherUserUid: user.uid).subscribe(onSuccess: { (isBlocked) in
            self.hideLoadingViewAlert {
                if isBlocked {
                    self.showAlert(type: .error, message: Strings.error)
                } else {
                    let channel = UUID().uuidString
                    let callUUID = UUID().uuidString
                    
                    let fireCall = FireCall(callId: FireManager.generateKey(), callUUID: callUUID, user: user, callType: callType, callDirection: .OUTGOING, channel: channel, timestamp: Int(Date().currentTimeMillis()), duration: 0, phoneNumber: user.phone, isVideo: callType.isVideo)
                    
                    self.performSegue(withIdentifier: "toCallingVC", sender:fireCall)

                }
            }



        }) { (error) in
            self.hideLoadingViewAlert()

            self.showAlert(type: .error, message: Strings.error)
        }.disposed(by: disposeBag)
    }

   






    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CallingVC {
            if let fireCall = sender as? FireCall{
                
            
                controller.initialize(fireCall: fireCall)

            }
        }
    }
}

extension BaseVC: NotificationViewDelegate {
    func notificationViewDidTap(_ notificationView: NotificationView) {
        swizzledNotificationViewDidTap(notificationView)
    }

}
