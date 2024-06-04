//
//  BroadcastInfoTableVC.swift
//  FireApp
//
//  Created by Devlomi on 10/20/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

class BroadcastInfoTableVC: BaseTableVC {
    let maxUsers = Config.MAX_BROADCAST_USERS_COUNT
    private var broadcastUser: User!

    private var broadcast: Broadcast!
    private var allUsers: [User]!

    private var currentUsersManaged: List<User>!
    private var currentUsersArr = [User]()
    private var usersToAdd = [String]()
    private var usersToRemove = [String]()

    private var searchController: UISearchController!
    private var isInSearchMode = false
    private var searchResults: [User]!

    override func viewDidLoad() {
        super.viewDidLoad()

        broadcast = broadcastUser.broadcast!
        //saved users in Realm (not editable)
        currentUsersManaged = broadcast.users
        //a copy of currentUsers (editable)
        currentUsersArr = Array(currentUsersManaged)

        allUsers = RealmHelper.getInstance(appRealm).getUsers().sortAddedUsersToBroadcast(broadcastUsers: currentUsersManaged)
        searchResults = allUsers

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))

        updateUsersCountLbl()

        initSearchController()

    }

    private func initSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar


    }

    @objc private func saveTapped() {
        showLoadingViewAlert()
        BroadcastManager.updateBroadcastUsers(broadcastId: broadcastUser.uid, usersToRemoveUids: usersToRemove, usersToAddUids: usersToAdd, updatedLocalUsers: currentUsersArr).subscribe(onCompleted: {
            self.hideLoadingViewAlert {

                self.navigationController?.popViewController(animated: true)
            }

        }) { (error) in
            self.showAlert(type: .error, message: Strings.error)
            self.hideLoadingViewAlert()
        }.disposed(by: disposeBag)

    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return getDataSource().count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell") as! UITableViewCell
            cell.textLabel?.text = broadcastUser.userName
            return cell


        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: "broadcastCell", for: indexPath) as? BroadcastCell {
            let user = getDataSource()[indexPath.row]
            cell.bind(user: user, isUserAdded: currentUsersArr.contains(user))
            return cell
        }

        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let alert = UIAlertController(title: Strings.enter_broadcast_name, message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = Strings.broadcast_name
            }
            alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: Strings.update, style: .default, handler: { (_) in
                let broadcastTitle = alert.textFields?[0].text ?? ""
                self.showLoadingViewAlert()
                BroadcastManager.changeBroadcastName(broadcastId: self.broadcast.broadcastId, newTitle: broadcastTitle).subscribe(onCompleted: {
                    self.hideLoadingViewAlert()
                    tableView.reloadSections([0], with: .none)
                }, onError: { (error) in
                        self.hideLoadingViewAlert()
                        self.showAlert(type: .error, message: Strings.error)
                    }).disposed(by: self.disposeBag)
            }))
            self.present(alert, animated: true, completion: nil)
        }

        else {

            let user = getDataSource()[indexPath.row]
            if currentUsersArr.contains(user) {
                self.tableView(tableView, didDeselectRowAt: indexPath)
            } else {
                if canAdd() {
                    currentUsersArr.append(user)
                    usersToAdd.append(user.uid)
                    usersToRemove.removeAll(where: { $0 == user.uid })
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
            updateUsersCountLbl()
        }
    }


    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let user = allUsers[indexPath.row]



        if currentUsersArr.contains(user) {
            currentUsersArr.removeAll(where: { $0.uid == user.uid })
            usersToAdd.removeAll(where: { $0 == user.uid })
            usersToRemove.append(user.uid)
            tableView.reloadRows(at: [indexPath], with: .none)
        }

        updateUsersCountLbl()
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return Strings.broadcast_name
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 30
        }
        return 0
    }

    private func canAdd() -> Bool {
        return currentUsersArr.count <= maxUsers
    }

    private func getDataSource() -> [User] {
        return isInSearchMode ? searchResults : allUsers
    }

    func initialize(user: User) {
        broadcastUser = user
    }

    private func updateUsersCountLbl() {

        navigationItem.title = "\(currentUsersArr.count) / \(maxUsers)"
    }


}
extension BroadcastInfoTableVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        searchResults = RealmHelper.getInstance(appRealm).searchForUser(query: searchText).sortAddedUsersToBroadcast(broadcastUsers: currentUsersManaged)

        isInSearchMode = searchText.isNotEmpty
        tableView.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isInSearchMode = false
        tableView.reloadData()
    }
}

class BroadcastCell: UserCell {
    @IBOutlet weak var selectedCircle: UIImageView!

    func bind(user: User, isUserAdded: Bool) {
        super.bind(user: user)

        let imageName = isUserAdded ? "check_circle_filled" : "circle"
        let image = UIImage(named: imageName)
        selectedCircle.image = image
    }
}


extension Results where Element == User {

    //sort the users that added to broadcast to be at the top
    func sortAddedUsersToBroadcast(broadcastUsers: List<User>) -> [User] {

        return self.sorted { (a, b) -> Bool in
            return broadcastUsers.contains(a)
        }

    }
}
