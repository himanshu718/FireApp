//
//  DeleteAccountVC.swift
//  FireApp
//
//  Created by iMac on 12/10/23.
//  Copyright © 2023 Devlomi. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class DeleteAccountVC: UIViewController {
    private var loadingAlertView: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Security"
        self.navigationController?.navigationBar.topItem?.title = ""
    }
    
    
    @IBAction func switchFigerprintOpen(_ sender: UISwitch) {
    }
    

    @IBAction func btnDeleteAccount(_ sender: UIButton) {
        let alert = UIAlertController(title: Strings.delete_account, message: Strings.delete_account_confirmation, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Strings.delete, style: .destructive, handler: { _ in
            self.showLoadingViewAlert()
            FireConstants.mainRef.child("users").child(FireManager.getUid()).removeValue { error, ref in
                self.hideLoadingViewAlert {
                    if let _ = error{
                        self.showAlert(type: .error, message: Strings.unknown_error)
                        return
                    }
                    FireManager.logoutAndDelete()
                    AppDelegate.shared.goToInitialVC()
                }

            }
        }))
        present(alert,animated: true)
    }
    
    func showLoadingViewAlert() {
        loadingAlertView = loadingAlert()
        self.present(loadingAlertView!, animated: true)

    }
    func hideLoadingViewAlert(_ completion: (() -> Void)? = nil) {
        loadingAlertView?.dismiss(animated: true, completion: completion)
    }

    

}
