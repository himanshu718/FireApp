//
//  TabBarVC.swift
//  FireApp
//
//  Created by Devlomi on 9/18/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
class TabBarVC: UITabBarController {

    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
        let operatorVC = OperatorViewController(nibName: "OperatorViewController", bundle: nil)
        operatorVC.netbalance = user.netsAvailable
        
        if user?.userType.lowercased() == "operator" {
            self.viewControllers?[0] = operatorVC
            self.tabBar.items![0].title = "Home"
            self.tabBar.items![0].image = #imageLiteral(resourceName: "ic_sticker_small")
        }
        
        if !UserDefaultsManager.userDidLogin() {
            NotificationCenter.default.post(name: Notification.Name("userDidLogin"), object: nil)
            
            //request permissions for first time
            Permissions.requestContactsPermissions(completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.navigationItem.title = " "
    }
    
    func goToUsersVC() {
        performSegue(withIdentifier: "toUsersVC", sender: nil)
    }
    
    func segueToChatVC(user:User) {
          performSegue(withIdentifier: "toChatVC", sender: user)
      }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let controller = segue.destination as? UsersVCNavController {
            controller.navigationDelegate = self
        } else if let controller = segue.destination as? ChatViewController, let user = sender as? User {
            controller.initialize(user: user,delegate: self)
        }
    }
    
   
}
