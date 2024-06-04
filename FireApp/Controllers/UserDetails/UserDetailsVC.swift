//
//  UserDetailsVC.swift
//  FireApp
//
//  Created by Devlomi on 9/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import Hero
import DateTimePicker



class UserDetailsVC: UserDetailsBase {


    override func viewDidLoad() {
        super.viewDidLoad()




    }








    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return addUserImageHeader()
        }
        return super.tableView(tableView, viewForHeaderInSection: section)
    }





    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = tableView.cellForRow(at: indexPath) {

            let tag = cell.tag

            //hide rows if needed
            if shouldHideMediaRow && tag == CellTags.media {
                return 0
            }

            if shouldHideMuteRow && tag == CellTags.mute {
                return 0
            }

        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }






    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        let tag = cell.tag

        if indexPath == IndexPath(row: 0, section: 0) {
            cell.textLabel?.text = user.userName
            cell.detailTextLabel?.text = user.phone
        }
        if indexPath == IndexPath(row: 1, section: 0) {
            cell.textLabel?.text = user.status
        }


        if tag == CellTags.mute {
            if let chat = chat {
                cell.detailTextLabel?.text = chat.isMuted ? Strings.yes.uppercased() : Strings.no.uppercased()
            }
        }
        if tag == CellTags.media {
            cell.detailTextLabel?.text = "\(mediaCount)"

        }

        if tag == CellTags.blockUser {
            if let chat = chat, let user = chat.user {
                cell.textLabel?.text = user.isBlocked ? Strings.unblock : Strings.block
            }
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






        case CellTags.blockUser:
            //block user

            let title = user.isBlocked ? Strings.unblock : Strings.block
            let alertController = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)
            let blockAction = UIAlertAction(title: title, style: .default) { (_) in

                self.showLoadingViewAlert()
                FireManager.setUserBlocked(blockedUserUid: self.user.uid, setBlocked: !self.user.isBlocked, appRealm: appRealm).subscribe(onCompleted: {
                    //cancel loading indicator...
                    self.hideLoadingViewAlert {
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }

                }, onError: { (error) in
                        self.hideLoadingViewAlert {
                            self.showAlert(type: .error, message: Strings.error)
                        }
                    }).disposed(by: self.disposeBag)
            }
            let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

            alertController.addAction(blockAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)


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

        case CellTags.scheduleMessage:

            let alert = UIAlertController(title: nil, message: "Schedule Messages is not enabled in this Demo", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: nil))
            self.present(alert, animated: true)
            
//            let min = NSCalendar.current.date(byAdding: .minute, value: 5, to: Date())
//
//
//            let max = NSCalendar.current.date(byAdding: .day, value: 29, to: Date())
//
//            let picker = DateTimePicker.create(minimumDate: min, maximumDate: max)
//            picker.completionHandler = { date in
//
//                self.delegate?.didClickScheduleMessage(date: date)
//
//                self.navigationController?.popViewController(animated: true)
//            }
//
//
//            picker.show()

            break


        default:
            break
        }
    }




}







