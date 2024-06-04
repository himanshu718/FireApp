//
//  UserDetailsBase.swift
//  FireApp
//
//  Created by Devlomi on 11/21/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import Hero

struct CellTags {
    static let userName = 99
    static let userNumber = 98
    static let groupName = 97

    static let media = 1
    static let search = 2
    static let mute = 3

    static let onlyAdminsCanPost = 4
    static let addParticipants = 5
    static let inviteViaLink = 6
    static let showParticipants = 7
    static let copyGroupVoiceCallLink = 77
    


    static let blockUser = 8
    static let clearChat = 9
    static let exitGroup = 10
    static let scheduleMessage = 22
}
protocol UserDetailsDelegate {
    func didClickSearch()
    func didClickScheduleMessage(date:Date)
}

class UserDetailsBase: BaseTableVC {

    var delegate: UserDetailsDelegate?

    var shouldHideGroupAdminRows = false
    var shouldHideMediaRow = false
    var shouldHideMuteRow = false
    var shouldHideExitGroup = false
    var mediaCount = 0

    var chat: Chat?
    var user: User!
    var loadingAlertView: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()


        FireManager.checkAndDownloadUserPhoto(user: user,appRealm: appRealm).subscribe(onSuccess: { (arg0) in
            let (thumbImg, fullPhotoPath) = arg0

            self.tableView.reloadSections([0], with: .none)


        }, onError: nil).disposed(by: disposeBag)
    }


    @objc func userImageTapped() {
        navigationController?.hero.isEnabled = true
        performSegue(withIdentifier: "toPreviewUserImage", sender: nil)
    }

    @objc func cameraTapped() {

        let alertController = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)

        let takePhotoAction = UIAlertAction(title: Strings.take_photo, style: .default) { (_) in

            let cameraViewController = CropImageRequest.getRequest { (image, asset) in
                if let image = image {
                    self.changeGroupImage(image: image)
                }
                self.dismiss(animated: true, completion: nil)
            }

            self.present(cameraViewController, animated: true, completion: nil)
        }

        let pickImage = UIAlertAction(title: Strings.pick_image, style: .default) { (_) in
            let imagePickerController = ImagePickerRequest.getRequest(delegate: self)
            imagePickerController.maxCount = 1
            imagePickerController.mediaTypes = [.Photo]

            self.present(imagePickerController, animated: true, completion: nil)
        }

        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

        alertController.addAction(takePhotoAction)
        alertController.addAction(pickImage)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)


    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 256.0
        }
        return 0.1
    }

    func addUserImageHeader() -> UIView {
        let uiView = UIView()

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false

        if user.userLocalPhoto != "" {
            imageView.image = UIImage(contentsOfFile: user.userLocalPhoto)
        } else {
            imageView.image = user.thumbImg.toUIImage()
        }

        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userImageTapped)))

        uiView.addSubview(imageView)

        imageView.hero.id = "user_image_id"
        imageView.hero.modifiers = [.fade, .scale(0.8)]
        imageView.isOpaque = true

        imageView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: uiView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: uiView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor).isActive = true


        if !shouldHideGroupAdminRows {
            let cameraButton = UIButton(image: #imageLiteral(resourceName: "ic_camera"))
            cameraButton.translatesAutoresizingMaskIntoConstraints = false
            cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)


            cameraButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
            cameraButton.heightAnchor.constraint(equalToConstant: 25).isActive = true

            uiView.addSubview(cameraButton)

            cameraButton.trailingAnchor.constraint(equalTo: uiView.trailingAnchor, constant: -25).isActive = true
            cameraButton.bottomAnchor.constraint(equalTo: uiView.bottomAnchor, constant: -16).isActive = true
        }
        return uiView


    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? MediaPreviewVC {
            controller.initialize(chatId: user.uid)
        } else if let controller = segue.destination as? GroupUsersVC {
            if segue.identifier == "toGroupUsersShow" {
                controller.initialize(groupOrBroadcastId: user.uid, mode: .show, isBroadcast: user.isBroadcastBool)
            } else {
                controller.initialize(groupOrBroadcastId: user.uid, mode: .add, isBroadcast: user.isBroadcastBool)
            }

        } else if let controller = segue.destination as? ShareGroupLinkVC {
            controller.initialize(groupId: user.uid)
        } else if let controller = segue.destination as? PreviewUserImage {
            controller.initialize(user: user)
        }else if let controller = segue.destination as? ScheduledMessagesTableVC{
            
        }

    }





    public func initialize(user: User, _ delegate: UserDetailsDelegate? = nil) {
        self.user = user
        chat = RealmHelper.getInstance(appRealm).getChat(id: user.uid)
        mediaCount = RealmHelper.getInstance(appRealm).getMediaInChat(chatId: user.uid).count
        if let group = user.group {
            shouldHideGroupAdminRows = !group.isAdmin(adminUid: FireManager.getUid()) || !group.isActive
            shouldHideExitGroup = !group.isActive

        } else {
            shouldHideGroupAdminRows = true
        }
        shouldHideMediaRow = mediaCount == 0
        shouldHideMuteRow = chat == nil
        self.delegate = delegate
    }


}

extension UserDetailsBase {




    private func changeGroupImage(image: UIImage) {
        self.showLoadingViewAlert()
        GroupManager.changeGroupImage(user: self.user, image: image).subscribe(onCompleted: {
            self.hideLoadingViewAlert()
            self.showAlert(type: .success, message: Strings.done)
            self.tableView.reloadSections([0], with: .none)
        }, onError: { error in
                self.hideLoadingViewAlert()
                self.showAlert(type: .error, message: Strings.error)
            }).disposed(by: self.disposeBag)
    }


}
extension UserDetailsBase: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 25
    }
}

extension UserDetailsBase: MTImagePickerControllerDelegate {
    func imagePickerController(picker: MTImagePickerController, didFinishPickingWithPhotosModels models: [MTImagePickerPhotosModel]) {
        models[0].getImageAsync { (image) in
            if let image = image {
                self.changeGroupImage(image: image)
            }
        }
    }
}


