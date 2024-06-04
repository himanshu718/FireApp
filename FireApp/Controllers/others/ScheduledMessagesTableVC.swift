//
//  ScheduledMessagesTableVC.swift
//  FireApp
//
//  Created by Devlomi on 4/22/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

class ScheduledMessagesTableVC: UITableViewController {
    private var uid = ""
    private let disposeBag = DisposeBag()
    private var scheduledMessages: Results<ScheduledMessage>!
    override func viewDidLoad() {
        super.viewDidLoad()

        scheduledMessages = appRealm.objects(ScheduledMessage.self).sorted(byKeyPath: "scheduledAt",ascending: false)
        
    }



    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduledMessages.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleMessageCell", for: indexPath) as? ScheduledMessageCell {

            let scheduledMessage = scheduledMessages[indexPath.row]
            cell.bind(scheduledMessage: scheduledMessage)
            return cell
        }


        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let scheduledMessage = scheduledMessages[indexPath.row]


        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if let previewScheduledMessagesVC = storyboard.instantiateViewController(withIdentifier: "PreviewScheduledMessage") as? PreviewScheduledMessageVC {
            previewScheduledMessagesVC.initialize(scheduledMessageId: scheduledMessage.messageId)

            self.present(previewScheduledMessagesVC, animated: true, completion: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PreviewScheduledMessageVC, let messageId = sender as? String {
            controller.initialize(scheduledMessageId: messageId)
        }
    }



    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deletAction = UIContextualAction(style: .destructive, title: Strings.delete) { (_, _, actionPerformed) in

            let deleteAlert = self.properAlert(title: nil, message: nil, preferredStyle: .actionSheet)

            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

            let deleteAction = UIAlertAction(title: Strings.delete, style: .destructive, handler: { (_)in
                
                let scheduledMessageId = self.scheduledMessages[indexPath.row].messageId
                
                ScheduledMessagesManager(disposeBag: self.disposeBag).deleteScheduledMessage(messageId: scheduledMessageId)

                actionPerformed(true)

            })

            deleteAlert.addAction(cancelAction)
            deleteAlert.addAction(deleteAction)
            self.present(deleteAlert, animated: true, completion: nil)

        }

        return UISwipeActionsConfiguration(actions: [deletAction])


    }
    
    
    func initialize(userId: String) {
        uid = userId
    }
}

class ScheduledMessageCell: UITableViewCell {
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var scheduledAtLbl: UILabel!
    @IBOutlet weak var timeToExecuteLbl: UILabel!
    @IBOutlet weak var messageTypeText: UILabel!
    @IBOutlet weak var messageTypeImg: UIImageView!
    @IBOutlet weak var stateLbl: UILabel!

    func bind(scheduledMessage: ScheduledMessage) {
        if let user = RealmHelper.getInstance(appRealm).getUser(uid: scheduledMessage.toId) {
            userImg.image = user.thumbImg.toUIImage()
            userNameLbl.text = user.userName

            scheduledAtLbl.text = "Scheduled at: " + TimeHelper.getDateAndTime(date: scheduledMessage.scheduledAt.toDate())

            timeToExecuteLbl.text = "Time to Execute: " + TimeHelper.getDateAndTime(date: scheduledMessage.timeToExecute.toDate())

            let messageTypeString = MessageTypeHelper.getTypeText(type: scheduledMessage.typeEnum).isEmpty ? "Text" : MessageTypeHelper.getTypeText(type: scheduledMessage.typeEnum)

            messageTypeText.text = messageTypeString


            let messageImageName = MessageTypeHelper.getMessageTypeImage(type: scheduledMessage.typeEnum).isEmpty ? "chat" : MessageTypeHelper.getMessageTypeImage(type: scheduledMessage.typeEnum)

            messageTypeImg.image = UIImage(named: messageImageName)
            
            stateLbl.text = "Status: " + scheduledMessage.status.getText()

        }
    }

}
