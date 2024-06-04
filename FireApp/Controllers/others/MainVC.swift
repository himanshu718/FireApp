//
//  MainVC.swift
//  FireApp
//
//  Created by Devlomi on 1/28/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import Permission

@available(iOS 13.0, *)
class MainVC: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var continueBtn: UIButton!
    let privacyPolicyWord = Strings.privacy_policy

    fileprivate func setText() {
        let privacyPolicyInfo = String(format: Strings.privacy_policy_info, privacyPolicyWord)
        if let range = privacyPolicyInfo.range(of: privacyPolicyWord) {
            let nsRange = NSRange(range: range, in: privacyPolicyInfo)
            let attributedString = NSMutableAttributedString(string: privacyPolicyInfo)
            let url = URL(string: Config.privacyPolicyLink)



            //setting default font
            let fontRange = NSRange(location: 0, length: privacyPolicyInfo.count)
            attributedString.addAttributes([.font: textView.font], range: fontRange)
            // Set the 'click here' substring to be the link
            attributedString.addAttributes([.link: url], range: nsRange)



            self.textView.attributedText = attributedString
            self.textView.isUserInteractionEnabled = true
            self.textView.isEditable = false

            // Set how links should appear: blue and underlined
            self.textView.linkTextAttributes = [
                .foregroundColor: UIColor.systemBlue,
            ]
            
        } else {
            textView.text = privacyPolicyInfo
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setText()



        continueBtn.addTarget(self, action: #selector(continueBtnTapped), for: .touchUpInside)
    }
    
    
    @objc private func continueBtnTapped() {

//        let alert = UIAlertController(title: Strings.privacy_policy_title, message: Strings.privacy_policy_message, preferredStyle: .alert)
//
//        alert.addAction(UIAlertAction(title: Strings.cancel, style: .default, handler: nil))
//
//        alert.addAction(UIAlertAction(title: Strings.agree, style: .default, handler: { (_) in
//            if Permissions.isNotificationPermissionsGranted() {
//                self.goToRootVC()
//            } else {
//                let permission: Permission = .notifications
//
//                let alert = permission.deniedAlert // or permission.disabledAlert
//
//                alert.title = Strings.notifications_settings_blocked
//                alert.message = nil
//                alert.cancel = Strings.cancel
//                alert.settings = Strings.settings
//
//                permission.deniedAlert = alert
//
//                permission.request { status in
//                    self.goToRootVC()
//                }
//
//
//            }
//        }))
//
//
//        self.present(alert, animated: true, completion: nil)

        let alert = UIAlertController(title: Strings.privacy_policy_title, message: nil, preferredStyle: .alert)
        let textView = UITextView()
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let controller = UIViewController()

        textView.frame = controller.view.frame
        controller.view.addSubview(textView)
        textView.backgroundColor = .clear

        alert.setValue(controller, forKey: "contentViewController")

        let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150)
        alert.view.addConstraint(height)

        let privacyPolicyMessage = Strings.privacy_policy_message

        if let range = privacyPolicyMessage.range(of: privacyPolicyWord),let url = URL(string: Config.privacyPolicyLink) {
            let nsRange = NSRange(range: range, in: privacyPolicyMessage)
            let attributedString = NSMutableAttributedString(string: privacyPolicyMessage)
            



            attributedString.addAttributes([.link: url], range: nsRange)



            textView.attributedText = attributedString
            textView.isUserInteractionEnabled = true
            textView.isEditable = false

            // Set how links should appear: blue and underlined
            textView.linkTextAttributes = [
                    .foregroundColor: UIColor.systemBlue,
            ]

        } else {
            textView.text = privacyPolicyMessage
        }



        alert.addAction(UIAlertAction(title: Strings.cancel, style: .default, handler: nil))

        alert.addAction(UIAlertAction(title: Strings.agree, style: .default, handler: { (_) in
            if Permissions.isNotificationPermissionsGranted() {
                self.goToRootVC()
            } else {
                let permission: Permission = .notifications

                let alert = permission.deniedAlert // or permission.disabledAlert

                alert.title = Strings.notifications_settings_blocked
                alert.message = nil
                alert.cancel = Strings.cancel
                alert.settings = Strings.settings

                permission.deniedAlert = alert

                permission.request { status in
                    self.goToRootVC()
                }


            }
        }))

        present(alert, animated: true, completion: nil)

    }

    func goToRootVC() {
        UserDefaultsManager.setAgreedToPolicy(bool: true)
        let vc = LoginVC()
        AppDelegate.shared.window?.rootViewController = vc

    }
}
