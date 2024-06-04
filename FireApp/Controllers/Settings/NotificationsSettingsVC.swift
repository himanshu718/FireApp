//
//  NotificationsVC.swift
//  FireApp
//
//  Created by Devlomi on 11/16/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class NotificationsSettingsVC: BaseTableVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Notification"
        self.navigationController?.navigationBar.topItem?.title = ""

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        //add switch for notifications
        if indexPath.row == 0 {
            let switchView = UISwitch(frame: .zero)
            switchView.tag = indexPath.row // for detect which row switch Changed
            switchView.setOn(UserDefaultsManager.areNotificationsOn(), animated: false)
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        }
        //set current ringtone name
        if indexPath.row == 1 {
            let ringtoneName = UserDefaultsManager.getRingtoneName()
            cell.detailTextLabel?.text = ringtoneName
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    @objc private func switchChanged(_ sender: UISwitch!) {
        UserDefaultsManager.setNotificationsOn(bool: sender.isOn)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        //pick ringtones
        if indexPath.row == 1 {
            performSegue(withIdentifier: "toRingtones", sender: nil)
        }

    }

}
