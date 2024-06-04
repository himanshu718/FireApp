//
//  NewCallVC.swift
//  FireApp
//
//  Created by Devlomi on 11/9/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift

class NewCallVC: BaseSearchableVC {

    var users: Results<User>!

    @IBOutlet weak var searchViewContainer: UIView!
    @IBOutlet weak var tableView: UITableView!



    private var isInSearchMode = false
    private var searchResults: Results<User>!

    private var searchController: UISearchController!


    override func viewDidLoad() {
        super.viewDidLoad()


        users = RealmHelper.getInstance(appRealm).getUsers()

        tableView.delegate = self
        tableView.dataSource = self

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchViewContainer.addSubview(searchController.searchBar)



    }

}

extension NewCallVC: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isInSearchMode = false
        tableView.reloadData()

    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        searchResults = RealmHelper.getInstance(appRealm).searchForUser(query: searchText)

        isInSearchMode = searchText.isNotEmpty
        tableView.reloadData()

    }

  

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? CallingVC, let fireCall = sender as? FireCall {

            
            controller.initialize(fireCall: fireCall)
        }
    }
}

extension NewCallVC: UITableViewDelegate, UITableViewDataSource, NewCallDelegate {
    func didClickBtn(user: User, isVideo: Bool) {
        let callType = user.isGroupBool ? CallType.CONFERENCE_VIDEO : .VIDEO
        
        makeACall(user: user, callType : callType)
    }


    func getDataSource() -> Results<User> {
        return isInSearchMode ? searchResults : users
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getDataSource().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") as? NewCallUserCell {
            let user = getDataSource()[indexPath.row]
            cell.bind(user: user)
            cell.delegate = self
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = getDataSource()[indexPath.row]
        makeACall(user: user, callType: CallType.VOICE)
    }
}

protocol NewCallDelegate {
    func didClickBtn(user: User, isVideo: Bool)
}
class NewCallUserCell: UserCell {
    @IBOutlet weak var btnVoiceCall: UIButton!
    @IBOutlet weak var btnVideoCall: UIButton!

    private var user: User!
    var delegate: NewCallDelegate?

    override func bind(user: User) {
        super.bind(user: user)
        self.user = user
        btnVoiceCall.addTarget(self, action: #selector(btnVoiceTapped), for: .touchUpInside)
        btnVideoCall.addTarget(self, action: #selector(btnVideoTapped), for: .touchUpInside)
    }

    @objc private func btnVoiceTapped() {
        delegate?.didClickBtn(user: user, isVideo: false)
    }

    @objc private func btnVideoTapped() {
        delegate?.didClickBtn(user: user, isVideo: true)
    }
}
