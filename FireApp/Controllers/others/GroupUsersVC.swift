//
//  GroupUsersVC.swift
//  FireApp
//
//  Created by Devlomi on 9/28/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

enum GroupUsersMode {
    case create, show, add
}


class GroupUsersVC: BaseSearchableVC {

    var delegate: DismissViewController?

    //current added users
    private var EXTRA_COUNT = 0;

    private var isBroadcast = false

    var groupOrBroadcastId = ""
    var group: Group?
    var broadcast: Broadcast?
    //group or broadcast user
    var groupOrBroadcastUser: User?


    //all users in FireApp
    var allUsers: Results<User>!
    var notificationToken: NotificationToken?
    var notificationTokenSearch: NotificationToken?

    var loadingAlertView: UIAlertController?

    //users that the user selected to add to group
    var selectedUsers = [User]()
    //the current users if this group already exists and the user wants to add new users to it
    var currentUsers: List<User>?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!

    var titleLbl: UILabel!
    var subtitleLbl: UILabel!


    var nextNavItem: UIBarButtonItem!
    var addNavItem: UIBarButtonItem!


    //mode to determine if the user want to show participants of the group or if he wants to add new users to group OR if it's a new group
    var mode: GroupUsersMode = .show

    var isInSearchMode = false {
        didSet {
//            searchController.isActive = isInSearchMode
        }
    }
    var searchController: UISearchController!

    var searchResults: Results<User>!



    override func viewDidLoad() {
        super.viewDidLoad()

        allUsers = RealmHelper.getInstance(appRealm).getUsers()
        searchResults = allUsers

        groupOrBroadcastUser = RealmHelper.getInstance(appRealm).getUser(uid: groupOrBroadcastId)

        if isBroadcast {
            broadcast = groupOrBroadcastUser?.broadcast
        } else {
            group = groupOrBroadcastUser?.group
        }





        searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchContainer.addSubview(searchController.searchBar)

        titleLbl = UILabel()
        subtitleLbl = UILabel()

        let stackView = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        stackView.spacing = 2
        stackView.axis = .vertical
        stackView.alignment = .center

        navigationItem.titleView = stackView


        if let group = group {
            currentUsers = group.users
            EXTRA_COUNT = currentUsers?.count ?? 0

            if mode == .show {
                notificationToken = currentUsers?.observe { [weak self] (changes: RealmCollectionChange) in
                    guard let strongSelf = self else { return }

                    
              

                    strongSelf.updateUsersCountLbl()
                }




                updateUsersCountLbl()


            } else if mode == .create || mode == .add {
                titleLbl.text = Strings.add_participants

                subtitleLbl.textColor = .darkGray
                subtitleLbl.font = titleLbl.font.withSize(11)
                updateUsersCountLbl()

            }

        } else if let broadcast = broadcast {
            currentUsers = broadcast.users
            EXTRA_COUNT = currentUsers?.count ?? 0

            if mode == .show {
                notificationToken = currentUsers?.observe { [weak self] (changes: RealmCollectionChange) in
                    guard let strongSelf = self else { return }
                    changes.updateTableView(tableView: strongSelf.tableView)
                    strongSelf.updateUsersCountLbl()
                }

                updateUsersCountLbl()


            } else if mode == .create || mode == .add {
                titleLbl.text = Strings.add_participants

                subtitleLbl.textColor = .darkGray
                subtitleLbl.font = titleLbl.font.withSize(11)
                updateUsersCountLbl()

            }
        } else {
            //initialize new list if there are no users
            currentUsers = List()
        }


        tableView.delegate = self
        tableView.dataSource = self

        collectionView.delegate = self
        collectionView.dataSource = self

        nextNavItem = UIBarButtonItem(title: Strings.create, style: .done, target: self, action: #selector(nextTapped))
        nextNavItem.isEnabled = false

        addNavItem = UIBarButtonItem(title: Strings.add.uppercased(), style: .done, target: self, action: #selector(addTapped))
        addNavItem.isEnabled = false


        if mode == .add || mode == .create {
            title = Strings.add_participants
        }

        if mode == .add {
            navigationItem.rightBarButtonItem = addNavItem
            nextNavItem.hide()
        } else if mode == .create {
            navigationItem.rightBarButtonItem = nextNavItem
            addNavItem.hide()
        } else {
            addNavItem.hide()
            nextNavItem.hide()

        }



    }

    private func updateUsersCountLbl() {
        let currentUsersCount = currentUsers?.count ?? 0
        let totalUsersCount = currentUsersCount + selectedUsers.count
        subtitleLbl.text = "\(totalUsersCount) / \(getMaxUsersCount())"
    }

    private func getMaxUsersCount() -> Int {
        return isBroadcast ? Config.MAX_BROADCAST_USERS_COUNT: Config.MAX_GROUP_USERS_COUNT
    }

    @objc func addTapped() {
        if let group = group {
            showLoadingViewAlert()
            GroupManager.addParticipants(groupUser: groupOrBroadcastUser!, users: selectedUsers).subscribe(onCompleted: {
                self.hideLoadingViewAlert {
                    self.navigationController?.popViewController(animated: true)
                }


            }) { (error) in
                self.hideLoadingViewAlert()
                self.showAlert(type: .error, message: Strings.error)
            }.disposed(by: disposeBag)
        } else if let broadcast = broadcast {
            showLoadingViewAlert()

            BroadcastManager.addParticipant(broadcastId: broadcast.broadcastId, users: selectedUsers).subscribe(onCompleted: {
                self.hideLoadingViewAlert()
            }) { (error) in
                self.showAlert(type: .error, message: Strings.error)
                self.hideLoadingViewAlert()
            }.disposed(by: disposeBag)

        }

    }


    @objc func nextTapped() {
        if isBroadcast {
            let alert = UIAlertController(title: Strings.enter_broadcast_name, message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = Strings.broadcast_name
            }

            let createAction = UIAlertAction(title: Strings.create_broadcast, style: .default) { (_) in
                let broadcastName = alert.textFields?[0].text ?? Strings.create_broadcast

                self.showLoadingViewAlert()
                BroadcastManager.createNewBroadcast(broadcastName: broadcastName, users: self.selectedUsers).subscribe(onSuccess: { (broadcastUser) in
                    self.hideLoadingViewAlert {
                        self.delegate?.presentCompletedViewController(user: broadcastUser)
                        self.dismiss(animated: true, completion: nil)
                    }


                }, onError: { (error) in
                        self.hideLoadingViewAlert()
                        self.showAlert(type: .error, message: Strings.error)


                    }).disposed(by: self.disposeBag)

            }
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
            alert.textFields?[0].delegate = self
            alert.addAction(createAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let alert = UIAlertController(title: Strings.enter_group_name, message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = Strings.group_name
            }

            let createAction = UIAlertAction(title: Strings.create_group, style: .default) { (_) in
                let groupTitle = alert.textFields?[0].text ?? Strings.new_group
                self.showLoadingViewAlert()
                GroupManager.createNewGroup(groupTitle: groupTitle, users: self.selectedUsers).subscribe(onSuccess: { (groupUser) in
                    self.hideLoadingViewAlert {
                        self.delegate?.presentCompletedViewController(user: groupUser)
                        self.dismiss(animated: true, completion: nil)
                    }
                }, onError: { (error) in
                        self.hideLoadingViewAlert()
                    }).disposed(by: self.disposeBag)
            }

            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
            alert.textFields?[0].delegate = self
            alert.addAction(createAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    func initialize(groupOrBroadcastId: String = "", mode: GroupUsersMode, isBroadcast: Bool, delegate: DismissViewController? = nil) {
        self.mode = mode
        self.groupOrBroadcastId = groupOrBroadcastId
        self.isBroadcast = isBroadcast
        self.delegate = delegate
    }

    deinit {
        notificationToken = nil
    }


    func exitSearchMode() {
        //for some reason when creating a new Group, then entering search mode
        //then cancelling it, it dismisses the VC it self
        if mode == .create{
            searchController.searchBar.text = ""
            searchController.searchBar.resignFirstResponder()

            isInSearchMode = false
            tableView.reloadData()
        }else{
        if searchController.isActive {
        isInSearchMode = false
        searchController.isActive = false
        tableView.reloadData()

        }
        }
    }

}

extension GroupUsersVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 25
    }
}
extension GroupUsersVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "selectedUser", for: indexPath) as? SelectedUserCell {
            let user = selectedUsers[indexPath.row]
            cell.bind(user: user)
            return cell
        }

        return UICollectionViewCell()

    }
}

extension GroupUsersVC: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchController.dismiss(animated: true) {
        
        self.exitSearchMode()
//        }
//

    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {


        //get only users in group
        if mode == .show,let users = currentUsers{
            searchResults = RealmHelper.getInstance(appRealm).searchForUserInGroup(query: searchText, users:users)
            //get all users
        }else if mode == .add || mode == .create{
            searchResults = RealmHelper.getInstance(appRealm).searchForUser(query: searchText)
        }
        isInSearchMode = searchText.isNotEmpty
        tableView.reloadData()

    }

}

extension GroupUsersVC: UITableViewDelegate, UITableViewDataSource {

    private func animateCollectionViewHeight(newHeight: CGFloat) {
        collectionViewHeight.constant = newHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }



    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isInSearchMode {
            
            return searchResults.count
        } else {
            if mode == .create || mode == .add {
                return allUsers.count
            } else {
                return currentUsers?.count ?? 0
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCell(withIdentifier: "groupUserCell") as? GroupUserCell, let user = getUser(index: indexPath.row) {

            
            if mode == .add {
                if let currentUsers = currentUsers, currentUsers.contains(user) {
                    cell.selectionStyle = .none
                } else {
                    cell.selectionStyle = .default
                }
            }

            cell.bind(user: user, group: group, mode: mode, isUserSelected: selectedUsers.contains(user), isUserAlreadyAddedBefore: currentUsers?.contains(user) ?? false)

            return cell
        }

        return UITableViewCell()
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = getUser(index: indexPath.row) else {
            return
        }


        if mode == .add || mode == .create {

            if let currentUsers = currentUsers {
                if currentUsers.contains(user) {
                    return
                }

                if !canAddUsers() {
                    return
                }
            }



            if selectedUsers.contains(user) {
                self.tableView(tableView, didDeselectRowAt: indexPath)
            } else {
                selectedUsers.append(user)
                tableView.reloadRows(at: [indexPath], with: .none)
            }

            if !selectedUsers.isEmpty {
                animateCollectionViewHeight(newHeight: 90)
            }


            collectionView.reloadData()

            nextNavItem.isEnabled = selectedUsers.isNotEmpty
            addNavItem.isEnabled = selectedUsers.isNotEmpty

            updateUsersCountLbl()

        } else {
            guard let group = group, user.uid != FireManager.getUid() else {
                return
            }

            let alert = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
            let messageAction = UIAlertAction(title: "\(Strings.message) \(user.userName)", style: .default) { (_) in
                self.exitSearchMode()
                self.performSegue(withIdentifier: "toChatVC", sender: user)
            }

            let removeFromGroupAction = UIAlertAction(title: Strings.remove_from_group, style: .destructive) { (action) in

                let confirmationAlert = self.properAlert(title: nil, message: Strings.remove_member_confirmation_message, preferredStyle: .actionSheet)

                let yesAction = UIAlertAction(title: Strings.yes, style: .destructive, handler: { (_) in
                    
                    let loadingAlertView = self.showLoadingWithSearch()
                    GroupManager.removeGroupMember(groupId: group.groupId, userToRemove: user.uid).subscribe(onCompleted: {

                        self.tableView.reloadData()

                        loadingAlertView.dismiss(animated: true)


                    }, onError: { (error) in
                            loadingAlertView.dismiss(animated: true)
                        }).disposed(by: self.disposeBag)
                })
                let noAction = UIAlertAction(title: Strings.no.uppercased(), style: .default, handler: nil)

                confirmationAlert.addAction(yesAction)
                confirmationAlert.addAction(noAction)

                alert.dismiss(animated: true)
                self.presentAlertWithSearch(confirmationAlert)


            }


            let makeAdmin = UIAlertAction(title: "\(Strings.make) \(user.userName) \(Strings.an_admin)", style: .default) { (_) in
                let confirmationAlert = self.properAlert(title: nil, message: Strings.make_admin_confirmation, preferredStyle: .actionSheet)
                let yesAction = UIAlertAction(title: Strings.yes, style: .default, handler: { (_) in
                    let loadingAlertView = self.showLoadingWithSearch()
                    GroupManager.makeGroupAdmin(groupUser: self.groupOrBroadcastUser!, userToSet: user, setAdmin: true).subscribe(onCompleted: {
                        tableView.reloadData()
                        loadingAlertView.dismiss(animated: true)

                    }, onError: { (error) in
                            loadingAlertView.dismiss(animated: true)
                        }).disposed(by: self.disposeBag)
                })
                let noAction = UIAlertAction(title: Strings.no.uppercased(), style: .default, handler: nil)

                confirmationAlert.addAction(yesAction)
                confirmationAlert.addAction(noAction)

                alert.dismiss(animated: true)
                self.presentAlertWithSearch(confirmationAlert)

            }

            let removeAdmin = UIAlertAction(title: "\(Strings.revoke_admin) \(user.userName)", style: .destructive) { (_) in
                let confirmationAlert = self.properAlert(title: nil, message: Strings.revoke_admin_confirmation, preferredStyle: .actionSheet)
                let yesAction = UIAlertAction(title: Strings.yes, style: .default, handler: { (_) in
                    let loadingAlertView = self.showLoadingWithSearch()
                    GroupManager.makeGroupAdmin(groupUser: self.groupOrBroadcastUser!, userToSet: user, setAdmin: false).subscribe(onCompleted: {
                        tableView.reloadData()
                        loadingAlertView.dismiss(animated: true)
                    }, onError: { (error) in
                            loadingAlertView.dismiss(animated: true)
                        }).disposed(by: self.disposeBag)
                })
                let noAction = UIAlertAction(title: Strings.no.uppercased(), style: .default, handler: nil)

                confirmationAlert.addAction(yesAction)
                confirmationAlert.addAction(noAction)

                alert.dismiss(animated: true)
                self.presentAlertWithSearch(confirmationAlert)
            }


            alert.addAction(cancelAction)
            alert.addAction(messageAction)

            if group.isAdmin(adminUid: FireManager.getUid()) {
                alert.addAction(removeFromGroupAction)

                if group.isAdmin(adminUid: user.uid) {
                    alert.addAction(removeAdmin)
                } else {
                    alert.addAction(makeAdmin)
                }
            }

            self.presentAlertWithSearch(alert)

        }



    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let newVc = segue.destination as? ChatViewController, let user = sender as? User {
            newVc.initialize(user: user)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let user = getUser(index: indexPath.row) else {
            return
        }

        if mode == .add || mode == .create {
            if selectedUsers.contains(user) {
                selectedUsers.removeAll(where: { $0.uid == user.uid })
                tableView.reloadRows(at: [indexPath], with: .none)
            }


            collectionView.reloadData()

            if selectedUsers.isEmpty {
                animateCollectionViewHeight(newHeight: 0)
            }

            nextNavItem.isEnabled = selectedUsers.isNotEmpty
            updateUsersCountLbl()
        }
    }

    func getUser(index: Int) -> User? {
        var user: User?

        if isInSearchMode {
            return searchResults.getItemSafely(index: index) as? User
        } else {
            if mode == .create || mode == .add {
                user = allUsers.getItemSafely(index: index) as? User
            } else {
                user = currentUsers?[index]
            }
        }

        return user
    }



    func canAddUsers() -> Bool {
        return (selectedUsers.count + 1) <= (getMaxUsersCount() + EXTRA_COUNT)
    }


}

//horizontal selected users collection view
class SelectedUserCell: UICollectionViewCell {
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var userName: UILabel!

    func bind(user: User) {
        userImg.image = user.thumbImg.toUIImage()
        userName.text = user.userName
    }
}

class GroupUserCell: UserCell {
    @IBOutlet weak var selectCircle: UIImageView!

    @IBOutlet weak var isAdminLbl: UILabel!

    func bind(user: User, group: Group?, mode: GroupUsersMode, isUserSelected: Bool, isUserAlreadyAddedBefore: Bool) {
        super.bind(user: user)

        if mode == .add || mode == .create {
            //if this user was already added BEFORE opening this VC
            if isUserAlreadyAddedBefore {
                userStatusLbl.text = Strings.already_added
                let imageName = isUserAlreadyAddedBefore ? "check_circle_filled" : "circle"
                let image = UIImage(named: imageName)
                selectCircle.image = image
            } else {
                let imageName = isUserSelected ? "check_circle" : "circle"
                let image = UIImage(named: imageName)
                selectCircle.image = image


            }

            isAdminLbl.isHidden = true




        } else {
            if let group = group {
                isAdminLbl.isHidden = !group.isAdmin(adminUid: user.uid)
            } else {
                isAdminLbl.isHidden = true
            }

            selectCircle.isHidden = true
        }
    }



}

extension GroupUsersVC {
    func presentAlertWithSearch(_ alert: UIAlertController) {
        if searchController.isActive {
            searchController.present(alert, animated: true)
        } else {
            self.present(alert, animated: true)
        }
    }

    func showLoadingWithSearch() -> UIAlertController {
        loadingAlertView = loadingAlert()
        if searchController.isActive {
            searchController.present(loadingAlertView!, animated: true)
        } else {
            self.present(loadingAlertView!, animated: true)
        }

        return loadingAlertView!

    }


}
