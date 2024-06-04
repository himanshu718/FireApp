//
//  GroupInfoPreviewVC.swift
//  FireApp
//
//  Created by Devlomi on 3/1/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import BottomPopup
import RxSwift

class GroupInfoPreviewVC: BottomPopupViewController {
    private let disposeBag = DisposeBag()

    @IBOutlet weak var groupImg: UIImageView!
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var creadtedByLbl: UILabel!
    @IBOutlet weak var usersCollectionView: UICollectionView!
    @IBOutlet weak var btnJoin: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var loadingIndicatior: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var groupCountLbl: UILabel!

    var groupUsers = [User]()
    var groupLink: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        btnJoin.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        btnCancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        usersCollectionView.delegate = self
        usersCollectionView.dataSource = self

        GroupLinkUtil.checkAndFetchGroupPartialInfo(groupLink: groupLink).subscribe(onNext: { (groupUser, groupMembersCount) in
            self.groupImg.isHidden = false
            self.groupName.isHidden = false
            self.creadtedByLbl.isHidden = false
            self.usersCollectionView.isHidden = false
            self.btnJoin.isHidden = false
            self.btnCancel.isHidden = false
            self.groupCountLbl.isHidden = false

            self.loadingIndicatior.isHidden = true

            self.groupImg.image = groupUser.thumbImg.toUIImage()
            self.groupName.text = groupUser.userName
            self.groupCountLbl.text = "\(groupMembersCount) \(Strings.participants)"
            if let group = groupUser.group {
                self.creadtedByLbl.text = group.createdByNumber
                self.groupUsers.append(contentsOf: group.users)
                self.usersCollectionView.reloadData()
            }

        }, onError: { (error) in
                var errorMessage = ""
                switch error {
                case is AlreadyInGroupError:
                    errorMessage = Strings.already_in_group

                case is InvalidGroupLinkError:
                    errorMessage = Strings.invalid_group_link

                case is UserBannedFromGroupError:
                    errorMessage = Strings.cant_join_this_group
                default:
                    errorMessage = Strings.unknown_error
                }

                self.loadingIndicatior.isHidden = true
                self.errorLabel.isHidden = false
                self.errorLabel.text = errorMessage
                self.btnCancel.isHidden = false

            }
        ).disposed(by: disposeBag)
    }

    @objc private func joinTapped() {

        self.groupImg.isHidden = true
        self.groupName.isHidden = true
        self.creadtedByLbl.isHidden = true
        self.usersCollectionView.isHidden = true
        self.btnJoin.isHidden = true
        self.btnCancel.isHidden = true
        self.groupCountLbl.isHidden = true


        self.btnCancel.isHidden = true
        self.btnJoin.isHidden = true
        
        self.loadingIndicatior.isHidden = false
        
        GroupManager.joinViaGroupLink(groupLink: groupLink).subscribe(onError: { (error) in
            
            self.loadingIndicatior.isHidden = true

            self.errorLabel.isHidden = false
            self.errorLabel.text = Strings.error

        }, onCompleted: {
                self.cancelTapped()
            }).disposed(by: disposeBag)



    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    func initialize(groupLink: String) {
        self.groupLink = groupLink
    }

}
extension GroupInfoPreviewVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupUsers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "groupUser", for: indexPath) as? SelectedUserCell {
            let user = groupUsers[indexPath.row]
            cell.bind(user: user)
            return cell
        }

        return UICollectionViewCell()

    }
}
