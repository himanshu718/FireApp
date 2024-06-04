//
//  GroupUserDetailsTableVC.swift
//  FireApp
//
//  Created by Devlomi on 11/21/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class GroupUserDetailsTableVC: UserDetailsBase {



    override func viewDidLoad() {
        //show loading alert while loading the views
        //like hiding group's admin sections..
        self.showLoadingViewAlert()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.tableView.reloadData()
            self.hideLoadingViewAlert()
        }

        super.viewDidLoad()

    }









    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //add user image header
        if section == 0 {
            return addUserImageHeader()
        }



        return super.tableView(tableView, viewForHeaderInSection: section)
    }


    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        //add created at & created by labels at the bottom
        if section == 5 {
            if let group = user.group {
                let uiView = UIView()
                let createdByLbl = UILabel()
                createdByLbl.textColor = .darkGray
                createdByLbl.font = createdByLbl.font.withSize(12)

                if group.createdByNumber == FireManager.number! {
                    createdByLbl.text = "\(Strings.created_by) \(Strings.you)"

                } else {
                    var createdBy = ""
                    if let createdByUser = group.users.filter({ $0.phone == group.createdByNumber }).first {

                        createdBy = createdByUser.userName
                    } else {
                        createdBy = group.createdByNumber
                    }

                    createdByLbl.text = "\(Strings.created_by) \(createdBy)"

                }



                let createdAtLbl = UILabel()
                createdAtLbl.textColor = .darkGray
                createdAtLbl.font = createdAtLbl.font.withSize(12)
                let createdAtTime = TimeHelper.getDate(timestamp: "\(group.timestamp)".toDate())
                createdAtLbl.text = "\(Strings.created_at) \(createdAtTime)"


                let stackView = UIStackView(arrangedSubviews: [createdByLbl, createdAtLbl])
                stackView.translatesAutoresizingMaskIntoConstraints = false
                uiView.addSubview(stackView)

                stackView.topAnchor.constraint(equalTo: uiView.topAnchor, constant: 6).isActive = true

                stackView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor, constant: 8).isActive = true
                stackView.leadingAnchor.constraint(equalTo: uiView.trailingAnchor).isActive = true


                stackView.axis = .vertical
                stackView.spacing = 4
                uiView.addSubview(stackView)
                return uiView
            }
        }
        return nil
    }


    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {


        //height unneeded rows
        if let cell = tableView.cellForRow(at: indexPath) {

            let tag = cell.tag


            //hide group admin views
            if shouldHideGroupAdminRows {
                if tag == CellTags.onlyAdminsCanPost || tag == CellTags.addParticipants || tag == CellTags.inviteViaLink || tag == CellTags.copyGroupVoiceCallLink {
                    return 0
                }
            }



            if shouldHideMediaRow && tag == CellTags.media {
                return 0
            }

            if shouldHideMuteRow && tag == CellTags.mute {
                return 0
            }


            if cell.tag == CellTags.exitGroup && shouldHideExitGroup {
                return 0
            }

            if cell.tag == CellTags.inviteViaLink && shouldHideExitGroup {
                return 0
            }

            if cell.tag == CellTags.showParticipants && shouldHideExitGroup {
                return 0
            }

        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }





    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        let tag = cell.tag

        if indexPath == IndexPath(row: 0, section: 0) { // double-check this
            cell.textLabel?.text = user.userName
            cell.detailTextLabel?.text = user.phone
        }
        if indexPath == IndexPath(row: 1, section: 0) { // double-check this
            cell.textLabel?.text = user.status
        }


        if tag == CellTags.mute { // double-check this
            if let chat = chat {
                cell.detailTextLabel?.text = chat.isMuted ? Strings.yes.uppercased() : Strings.no.uppercased()
            }
        }

        if tag == CellTags.media { // double-check this
            cell.detailTextLabel?.text = "\(mediaCount)"

        }

        //if it's not an admin remove disclosure indicator
        if tag == CellTags.groupName {
            if shouldHideGroupAdminRows {
                cell.accessoryType = .none
            } else {
                cell.textLabel?.text = user.userName
                cell.accessoryType = .disclosureIndicator
            }
        }




        if tag == CellTags.onlyAdminsCanPost, let group = user.group {
            cell.detailTextLabel?.text = group.onlyAdminsCanPost ? Strings.yes.uppercased() : Strings.no.uppercased()
        }



        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        let tag = cell.tag
        switch tag {

        case CellTags.search:
            delegate?.didClickSearch()
            navigationController?.popViewController(animated: true)
            break
            //pop to ChatView and open search
        case CellTags.mute:
            //mute this user (show UIALertController)

            if let chat = chat {
                let title = chat.isMuted ? Strings.unMute : Strings.mute
                let alertController = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
                let muteAction = UIAlertAction(title: title, style: .default) { (_) in
                    RealmHelper.getInstance(appRealm).setChatMuted(chatId: chat.chatId, isMuted: !chat.isMuted)
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

                alertController.addAction(muteAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            break


        case CellTags.onlyAdminsCanPost:
            guard let group = user.group else {
                return
            }

            let title = group.onlyAdminsCanPost ? Strings.all_members_can_post: Strings.only_admins_can_post

            let alertController = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
            let muteAction = UIAlertAction(title: title, style: .default) { (_) in
                GroupManager.onlyAdminsCanPost(groupId: group.groupId, bool: !group.onlyAdminsCanPost).subscribe(onCompleted: {
                    tableView.reloadRows(at: [indexPath], with: .none)
                }, onError: { (error) in

                    }).disposed(by: self.disposeBag)
                tableView.reloadRows(at: [indexPath], with: .none)
            }

            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

            alertController.addAction(muteAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)

            break
            //show group settings



        case CellTags.groupName:
            if shouldHideGroupAdminRows {
                break
            } else {
                let alert = UIAlertController(title: Strings.enter_group_name, message: nil, preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.placeholder = Strings.group_name
                    textField.text = self.user.userName
                }

                let renameAction = UIAlertAction(title: Strings.update, style: .default) { (_) in
                    let groupTitle = alert.textFields![0].text!
                    self.showLoadingViewAlert()
                    GroupManager.changeGroupName(groupId: self.user.uid, groupTitle: groupTitle).subscribe(onCompleted: {
                        tableView.reloadSections([0], with: .none)
                        self.hideLoadingViewAlert()
                    }, onError: { (error) in
                            self.hideLoadingViewAlert()
                        }).disposed(by: self.disposeBag)

                }
                let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
                alert.textFields?[0].delegate = self
                alert.addAction(renameAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }






        case CellTags.clearChat:
            let alertController = properAlert(title: nil, message: Strings.clear_chat_confirmation_message, preferredStyle: .actionSheet)

            let deleteAction = UIAlertAction(title: Strings.delete.uppercased(), style: .destructive) { (_) in

                RealmHelper.getInstance(appRealm).clearChat(chatId: self.user.uid).subscribe().disposed(by: self.disposeBag)

            }
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)

            break

        case CellTags.exitGroup:
            guard !shouldHideExitGroup else {
                return
            }

            let alertController = properAlert(title: nil, message: Strings.exit_group_confirmation, preferredStyle: .actionSheet)
            let exitAction = UIAlertAction(title: Strings.exit_group, style: .destructive) { (_) in

                self.showLoadingViewAlert()
                GroupManager.exitGroup(groupId: self.user.uid).subscribe(onError: { (error) in
                    self.hideLoadingViewAlert()
                    self.showAlert(type: .error, message: Strings.error)

                }, onCompleted: {
                        self.hideLoadingViewAlert {
                            self.navigationController?.popViewController(animated: true)
                        }

                    }).disposed(by: self.disposeBag)


            }


            let cancelAction = Alerts.cancelAction

            alertController.addAction(exitAction)
            alertController.addAction(cancelAction)


            self.present(alertController, animated: true)

            break

        default:
            break
        }
    }
}

