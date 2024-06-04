//
//  RootNavController.swift
//  FireApp
//
//  Created by Devlomi on 9/22/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class RootNavController: UINavigationController, UIGestureRecognizerDelegate, DismissViewController {
    func presentCompletedViewController(user: User) {
    }
    
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
        
        AppDelegate.shared.fetchAllUsers()
        AppDelegate.shared.fetchGroups()
        AppDelegate.shared.listenerForNewChat()
       
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
        if user?.userType.lowercased() == "operator" {
//            let operatorVC = OperatorViewController(nibName: "OperatorViewController", bundle: nil)
//            operatorVC.netbalance = user.netsAvailable
//            self.viewControllers[0] = operatorVC
        }
        
        if !UserDefaultsManager.userDidLogin() {
            NotificationCenter.default.post(name: Notification.Name("userDidLogin"), object: nil)
            
            //request permissions for first time
            Permissions.requestContactsPermissions(completion: nil)
        }
    }

    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    func goToUsersVC() {
        performSegue(withIdentifier: "toUsersVC", sender: nil)
    }
    
    func segueToChatVC(user:User) {
          performSegue(withIdentifier: "toChatVC", sender: user)
      }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let controller = segue.destination as? UsersVCNavController {
//            controller.navigationDelegate = self
//        } else if let controller = segue.destination as? ChatViewController, let user = sender as? User {
//            controller.initialize(user: user,delegate: self)
//        }
    }
}
extension TabBarVC: DismissViewController {
    func presentCompletedViewController(user: User) {
    
       goToChatVC(user: user)
    }
}


extension TabBarVC: ChatVCDelegate {
    func goToChatVC(user:User){
        segueToChatVC(user: user)
    }
}
