//
//  UsersVC.swift
//  FireApp
//
//  Created by Devlomi on 9/21/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import Permission
protocol DismissViewController {

    func presentCompletedViewController(user: User)
}

class UsersVC: BaseSearchableVC {


    var notificationToken: NotificationToken?

    var refreshControl = UIRefreshControl()

    var delegate: DismissViewController?

    var searchController: UISearchController!




    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noUsersView: UIView!
    @IBOutlet weak var noUsersLbl: UILabel!
    @IBOutlet weak var inviteBtn: UIButton!
    @IBOutlet weak var searchContainer: UIView!

    var users: Results<User>!
    var searchResults: Results<User>!

    private var isInSearchMode = false

    fileprivate func syncContacts() {

        Permissions.requestContactsPermissions { (isAuthorized) in
            if isAuthorized {
                self.refreshControl.beginRefreshing()

                ContactsUtil.syncContacts(appRealm: appRealm).subscribe(onNext: { (user) in
                    self.updateNoUsersView()
                }, onError: { (error) in
                        self.showAlert(type: .error, message: Strings.error)
                        self.refreshControl.endRefreshing()
                        self.updateNoUsersView()
                    }, onCompleted: {
                        self.refreshControl.endRefreshing()
                        self.updateNoUsersView()


                }).disposed(by: self.disposeBag)
            }
        }
    }





    override func viewDidLoad() {
        super.viewDidLoad()

        users = RealmHelper.getInstance(appRealm).getUsers()

        searchResults = users

        tableView.delegate = self
        tableView.dataSource = self

        searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        self.definesPresentationContext = true

        searchController.searchBar.delegate = self
        searchContainer.addSubview(searchController.searchBar)


        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl

        notificationToken = users.observe { [weak self] (changes: RealmCollectionChange) in
            guard let strongSelf = self else {
                return
            }
            changes.updateTableView(tableView: strongSelf.tableView, section: 1)

        }


        //Sync Contacts for the first time
        if users.isEmpty {
            syncContacts()
        }


        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissVc))

        updateNoUsersView()
        setupNoUsersView()
    }
    private func updateNoUsersView() {
        tableView.isHidden = users.isEmpty
        noUsersView.isHidden = !users.isEmpty
    }

    private func setupNoUsersView() {
        noUsersLbl.text = ""
        inviteBtn.addTarget(self, action: #selector(btnInviteTapped), for: .touchUpInside)
    }


    @objc private func btnInviteTapped() {
        showInviteDialog()
    }


    @objc private func dismissVc() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func refresh(sender: AnyObject) {
        syncContacts()
    }

    deinit {
        notificationToken = nil
    }

    private func showInviteDialog() {

        let text = Strings.invite_text

        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash


        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }

}

extension UsersVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {

            return isInSearchMode ? 0 : 3
        }

        return getDataSource().count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "nonUserCell") {
                if indexPath.row == 0 {
                    let text = Strings.new_group
                    let imageName = "people"
                    let image = UIImage(named: imageName)
                    cell.textLabel?.text = text
                    cell.imageView?.image = image
                } else if indexPath.row == 1 {

                    let text = Strings.new_broadcast
                    let imageName = "rss"
                    let image = UIImage(named: imageName)
                    cell.textLabel?.text = text
                    cell.imageView?.image = image
                } else if indexPath.row == 2 {
                    let text = Strings.invite_to_app
                    let imageName = "invite"
                    let image = UIImage(named: imageName)
                    cell.textLabel?.text = text
                    cell.imageView?.image = image
                }



                return cell
            }

        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") as? UserCell {
                let user = getDataSource()[indexPath.row]
                cell.bind(user: user)
                return cell
            }
        }

        return UITableViewCell()

    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "toGroupUsers", sender: false)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: "toGroupUsers", sender: true)
            } else if indexPath.row == 2 {
                showInviteDialog()
            }
        } else if indexPath.section == 1 {
            searchController.isActive = false

            if isInSearchMode {
                self.dismiss(animated: true, completion: nil)
            }


            if let user = getDataSource().getItemSafely(index: indexPath.row) as? User {



                self.dismiss(animated: true)
                self.delegate?.presentCompletedViewController(user: user)


            }
        }
    }



    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GroupUsersVC {
            let isBroadcast = sender as! Bool

            vc.initialize(mode: .create, isBroadcast: isBroadcast, delegate: delegate)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    private func getDataSource() -> Results<User> {
        return isInSearchMode ? searchResults : users
    }
}

extension UsersVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        searchResults = RealmHelper.getInstance(appRealm).searchForUser(query: searchText)

        isInSearchMode = searchText.isNotEmpty
        tableView.reloadData()

    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isInSearchMode = false
        tableView.reloadData()

    }
}

class UsersVCNavController: UINavigationController, UINavigationControllerDelegate {
    var navigationDelegate: DismissViewController?


    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let usersVc = viewController as? UsersVC {
            usersVc.delegate = navigationDelegate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

}
