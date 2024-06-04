//
//  LoggedOutVC.swift
//  FireApp
//
//  Created by Devlomi on 5/18/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class LoggedOutVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        // Do any additional setup after loading the view.
    }
    

    override func viewDidAppear(_ animated: Bool) {
        let alert = UIAlertController(title: Strings.logged_out, message: Strings.logged_out_message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: { (_) in
            let vc = LoginVC()
            AppDelegate.shared.window?.rootViewController = vc
        }))
        
        present(alert, animated: true, completion: nil)
    }
  

}
