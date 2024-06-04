//
//  ViewContactDetailsVC.swift
//  FireApp
//
//  Created by Devlomi on 8/28/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import TTCardView
import ContactsUI

class ViewContactDetailsVC: BaseVC, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var userName: UILabel!

    @IBOutlet weak var addToContactsBtn: UIButton!
    @IBOutlet weak var addToContactsCard: TTCardView!


    @IBOutlet weak var tableView: UITableView!

    private var contact: RealmContact!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        addToContactsBtn.addTarget(self, action: #selector(addToContactsClicked), for: .touchUpInside)
        addToContactsCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addToContactsClicked)))

        userName.text = contact.name


    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue() as ContactNumbersCell
        let number = contact.realmList[indexPath.row].number
        cell.bind(number: number)
        return cell
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contact.realmList.count
    }

    @objc private func addToContactsClicked() {
        let controller = CNContactViewController(forNewContact: contact.toCNContact())
        controller.delegate = self
        let navigationController = UINavigationController(rootViewController: controller)
        self.present(navigationController, animated: true)
    }


    func initialize(contact: RealmContact) {
        self.contact = contact
    }

}
extension ViewContactDetailsVC: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        dismiss(animated: true, completion: nil)
    }
}
class ContactNumbersCell: UITableViewCell {
    @IBOutlet weak var numberLbl: UILabel!

    func bind(number: String) {
        numberLbl.text = number

    }


}
