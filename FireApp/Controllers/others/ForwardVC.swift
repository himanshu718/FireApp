//
//  ForwardVC.swift
//  FireApp
//
//  Created by Devlomi on 12/22/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift

class ForwardVC: BaseTableVC {
    var users: Results<User>!
    var searchResults: Results<User>!

    var selectedUsers = [User]()

    var messages: [Message]!

    var searchController: UISearchController!


    private var isInSearchMode = false
    override func viewDidLoad() {
        super.viewDidLoad()


        users = RealmHelper.getInstance(appRealm).getForwardList()
        searchResults = users

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        navigationItem.rightBarButtonItem?.isEnabled = selectedUsers.count > 0

        searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar

    }


    @objc private func doneTapped() {
        let loadingAlertView = loadingAlert()
        present(loadingAlertView, animated: true, completion: nil)
        let requestManager = RequestManager(disposeBag: disposeBag, downloadManager: DownloadManager(disposeBag: disposeBag), uploadManager: UploadManager(disposeBag: disposeBag, messageEncryptor: MessageEncryptor(encryptionHelper: EncryptionHelper())))
        
        for user in selectedUsers {
            for ogMessage in messages {
                let message = MessageCreator.createForwardedMessage(mMessage: ogMessage, user: user, fromId: FireManager.getUid(), appRealm: appRealm)
                requestManager.request(message: message, callback: nil,appRealm: appRealm)
            }
        }

        loadingAlertView.dismiss(animated: true) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "shareUserCell") as? ShareUserCell {
            let user = dataSource[indexPath.row]
            let circleImage = selectedUsers.contains(user) ? "check_circle" : "circle"

            cell.selectedImg.image = UIImage(named: circleImage)


            cell.bind(user: user)

            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = dataSource[indexPath.row]
        if selectedUsers.contains(user) {
            self.tableView(tableView, didDeselectRowAt: indexPath)

        } else {
            selectedUsers.append(user)
        }

        tableView.reloadRows(at: [indexPath], with: .none)

        navigationItem.rightBarButtonItem?.isEnabled = selectedUsers.count > 0
    }



    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let user = dataSource[indexPath.row]

        if !selectedUsers.contains(user) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            selectedUsers.removeAll(where: { $0.uid == user.uid })
        }

        tableView.reloadRows(at: [indexPath], with: .none)
        navigationItem.rightBarButtonItem?.isEnabled = selectedUsers.count > 0
    }
    var dataSource: Results<User> {
        return isInSearchMode ? searchResults : users
    }


}

class ShareUserCell: UserCell {
    @IBOutlet weak var selectedImg: UIImageView!

}


extension ForwardVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        searchResults = RealmHelper.getInstance(appRealm).searchForForwardUser(query: searchText)
     
        isInSearchMode = searchText.isNotEmpty
        tableView.reloadData()


    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isInSearchMode = false
        tableView.reloadData()

    }
}
