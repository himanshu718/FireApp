//
//  MyStatusesVC.swift
//  FireApp
//
//  Created by Devlomi on 11/4/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift

class MyStatusesVC: BaseTableVC {

    var notificationToken: NotificationToken?

    var userStatuses: UserStatuses!

    
    var statuses: Results<Status>!
    override func viewDidLoad() {
        super.viewDidLoad()



        userStatuses = RealmHelper.getInstance(appRealm).getUserStatuses(userId: FireManager.getUid())
        statuses = userStatuses!.getMyStatuses()
        notificationToken = statuses.observe { [weak self] (changes: RealmCollectionChange) in
            guard let strongSelf = self else{return}
            changes.updateTableView(tableView: strongSelf.tableView)
        }

        navigationController?.hero.isEnabled = true
        
        navigationItem.title = Strings.my_statuses

        getSeenCount()
     
    }

    func getSeenCount(){
        for status in statuses {
            StatusManager.getStatusSeenCount(statusId: status.statusId).subscribe().disposed(by: disposeBag)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statuses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "myStatusCell") as? MyStatusCell {
            let status = statuses[indexPath.row]
            cell.bind(status: status)
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let status = statuses[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: Strings.delete) { (_, _, actionPerformed) in



            let confirmationAlert = self.properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: Strings.delete_status, style: .destructive, handler: { (_) in
                actionPerformed(true)
                StatusManager.deleteStatus(statusId: status.statusId, statusType: status.type).subscribe(onCompleted: {

                }, onError: { (error) in
                    self.showAlert(type:.error,message: Strings.error_deleting_status)
                }).disposed(by: self.disposeBag)
            })
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: { (_) in
                actionPerformed(false)
            })


            confirmationAlert.addAction(deleteAction)
            confirmationAlert.addAction(cancelAction)

            self.present(confirmationAlert, animated: true, completion: nil)


        }

        return UISwipeActionsConfiguration(actions: [delete])
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toViewStatus", sender: nil)

    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ViewStatusVC {
            destination.initialize(userStatuses: userStatuses)
        }
    }
    
    
  

    
    deinit {
        notificationToken = nil
    }

}
class MyStatusCell: UITableViewCell {
    @IBOutlet weak var statusImg: UIImageView!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var userImgContainer:UIView!
    @IBOutlet weak var seenCountLbl: UILabel!
    @IBOutlet weak var textStatusLbL:UILabel!

    func bind(status: Status) {
        if let textStatus = status.textStatus{
            textStatusLbL.isHidden = false
            userImgContainer.layer.cornerRadius = userImgContainer.frame.width / 2
            userImgContainer.backgroundColor = textStatus.backgroundColor.toUIColor()
            userImgContainer.layer.borderColor = UIColor.red.cgColor
            textStatusLbL.text = textStatus.text
            
        }else{
            textStatusLbL.isHidden = true
            textStatusLbL.text = ""
            userImgContainer.backgroundColor = .clear
        }
        
        statusImg.hero.id = FireManager.getUid()
        statusImg.image = status.thumbImg.toUIImage()
        timeLbl.text = TimeHelper.getStatusTime(timestamp: status.timestamp.toDate())
        seenCountLbl.text = "\(status.seenCount)"
    }

}
