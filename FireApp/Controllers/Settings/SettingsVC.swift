//
//  SettingsVC.swift
//  FireApp
//
//  Created by Devlomi on 11/16/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class SettingsVC: BaseTableVC {

    var user: User!

    @IBOutlet weak var securityLbl: LocalizableLabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        securityLbl.text = "Security"
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        setNavbar()
        self.navigationItem.title = "Settings"
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(hexString: "#2196f5")
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.navigationItem.title = Strings.settings
    }
    
    

    //fix for a tint color bug on IOS 12 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let image = cell.imageView?.image?.withRenderingMode(.alwaysTemplate)
        if let image = image {
            cell.imageView?.image = image
            cell.imageView?.tintColor = .lightGray
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "toProfile", sender: nil)
        case 1:
            performSegue(withIdentifier: "toNotifications", sender: nil)
        case 2:
            performSegue(withIdentifier: "toDeleteAccount", sender: nil)
        case 3:
            performSegue(withIdentifier: "toChatSettings", sender: nil)
        case 4:
             performSegue(withIdentifier: "toPrivacyPolicy", sender: nil)
//            if let url = URL(string: Config.privacyPolicyLink) {
//                UIApplication.shared.open(url)
//            }
        case 5:
            performSegue(withIdentifier: "toAboutSettings", sender: nil)
            
        default:
            break
        }
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
            navigationController?.navigationBar.barTintColor = UIColor.blue
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }

}
