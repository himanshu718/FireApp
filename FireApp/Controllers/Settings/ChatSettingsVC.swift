//
//  ChatSettingsVC.swift
//  FireApp
//
//  Created by Devlomi on 11/16/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class ChatSettingsVC: BaseTableVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Chat Settings"
        self.navigationController?.navigationBar.topItem?.title = ""
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //select wallpaper
        if indexPath.section == 0 && indexPath.row == 1{
            let alert = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: Strings.restore_default_wallpaper, style: .default, handler: { (_) in
                self.removeWallpaper()
            }))

            alert.addAction(UIAlertAction(title: Strings.choose_from_camera_roll, style: .default, handler: { (_) in
                let imagePicker = ImagePickerRequest.getRequest(delegate: self)
                imagePicker.mediaTypes = [.Photo]
                imagePicker.maxCount = 1
                self.present(imagePicker, animated: true, completion: nil)
            }))

            alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
            //choose network types for AutoDownload
        else if indexPath.section == 1 {
            let mediaType = getMediaTypeByIndex(indexPath.row)

            performSegue(withIdentifier: "toNetworkTypes", sender: mediaType)

        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return Strings.chat_settings
        }else if section == 1{
            return Strings.media_auto_download
        }
        
        return nil
    }

    private func getMediaTypeByIndex(_ index: Int) -> MediaType {
        var mediaType: MediaType!

        switch index {
        case 0:
            mediaType = .photos
        case 1:
            mediaType = .videos
        case 2:
            mediaType = .audio
        default:
            mediaType = .documents
        }
        return mediaType

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                let switchView = UISwitch(frame: .zero)
                switchView.tag = indexPath.row // for detect which row switch Changed
                switchView.setOn(UserDefaultsManager.saveToCameraRoll(), animated: false)
                switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
                cell.accessoryView = switchView
            }
        }

        else if indexPath.section == 1 {
            let mediaType = getMediaTypeByIndex(indexPath.row)
            let autoDownloadString = UserDefaultsManager.getAutoDownloadTypeForMediaType(mediaType).string
            cell.detailTextLabel?.text = autoDownloadString
        }

        return cell
    }

    //enable or disable saving Received images to CameraRoll
    @objc private func switchChanged(_ sender: UISwitch!) {

        UserDefaultsManager.setSaveToCameraRoll(sender.isOn)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? NetworkTypesTableVC, let mediaType = sender as? MediaType {
            controller.initialize(mediaType: mediaType)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }



    private func setWallpaper(image: UIImage) {

        removeWallpaper()

        do {
            let path = DirManager.documentsDirectory().appendingPathComponent("WPPER\(UUID().uuidString).jpg")
            try image.toData(.medium)?.write(to: path)
            UserDefaultsManager.setWallpaperPath(path: path.path)
            showAlert(type:.success,message: Strings.wallpaper_changed)
        } catch let error {

        }

    }

    private func removeWallpaper() {
        let wallpaperPath = UserDefaultsManager.getWallpaperPath()
        if wallpaperPath != "" {
            do {
                //deleting old wallpaper
                try URL(fileURLWithPath: wallpaperPath).deleteFile()
                UserDefaultsManager.setWallpaperPath(path: "")
                showAlert(type:.success,message: Strings.wallpaper_restored)
            } catch let error {

            }
        }
    }

}
extension ChatSettingsVC: MTImagePickerControllerDelegate {

    func imagePickerController(picker: MTImagePickerController, didFinishPickingWithPhotosModels models: [MTImagePickerPhotosModel]) {
        models[0].getImageAsync { (image) in
            if let pickedImage = image {
                self.setWallpaper(image: pickedImage)
            }
        }
    }

}
