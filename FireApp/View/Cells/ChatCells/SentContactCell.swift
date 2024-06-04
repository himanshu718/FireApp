//
//  SentContactCell.swift
//  FireApp
//
//  Created by Devlomi on 8/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

protocol ContactCellDelegate {
    func didClickMessage(at index: IndexPath)
    func didClickSave(at index: IndexPath)
}
class SentContactCell: SentBaseCell {

    var delegate: ContactCellDelegate?


    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!

    @IBAction func messageTapped(_ sender: Any) {
        delegate?.didClickMessage(at: indexPath)
    }

    @IBAction func saveContactTapped(_ sender: Any) {
        delegate?.didClickSave(at: indexPath)
    }

  

    override func bind(message: Message,user:User) {
        super.bind(message: message,user:user)

        guard let contact = message.contact else {
            return
        }

        

        userLabel.text = contact.name

    }

}
