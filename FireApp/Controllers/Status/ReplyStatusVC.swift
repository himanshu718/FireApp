//
//  ReplyStatusVC.swift
//  FireApp
//
//  Created by Devlomi on 3/18/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import BottomPopup
import GrowingTextView
import UITextView_Placeholder
import Photos
import iRecordView
import JFContactsPicker
import ContactsUI
import AddressBook
import LocationPicker
import IQKeyboardManagerSwift
import KBStickerView

class ReplyStatusVC: BottomPopupViewController {
    @IBOutlet weak var textView: GrowingTextView!

    @IBOutlet weak var btnCamera: UIButton!

    @IBOutlet weak var btnSticker: UIButton!

    @IBOutlet weak var btnAdd: UIButton!

    @IBOutlet weak var typingViewContainer: UIView!
    @IBOutlet weak var recordButtonBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var recordViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var typingViewBottomConstraint: NSLayoutConstraint!

    private let defaultTypingViewBottomConstraint: CGFloat = 8 + 4

    //Replay Layout Views
    @IBOutlet weak var replyLayout: UIView!
    @IBOutlet weak var replyUserName: UILabel!
    @IBOutlet weak var replyIcon: UIImageView!
    @IBOutlet weak var replyDescTitle: UILabel!
    @IBOutlet weak var replyThumb: UIImageView!
    @IBOutlet weak var replyCancel: UIButton!

    private var user: User!
    private var status: Status!


    private var requestManager:RequestManager!
    private var downloadManager:DownloadManager!
    private var uploadManager:UploadManager!

    private let disposeBag = DisposeBag()

    private var kbStickerView: KBStickerView!

    var recorder: AudioRecorder!

    @IBOutlet weak var recordButton: SendButton!
    @IBOutlet weak var recordView: RecordView!

    var hasLayout = false


    @IBAction func btnSend(_ sender: Any) {
        sendMessage(textMessage: textView!.text!)


        replyFinished()


    }

    override var popupHeight: CGFloat {
        return 240
    }
    
    func updateStatus(_ status:Status)  {
        self.status = status
        showReplyLayout()
    }

    @IBAction func btnAdd(_ sender: Any) {
        let preferredStyle:UIAlertController.Style = UIDevice.isPhone ? .actionSheet : .alert
        let alert = ChooseActionAlertController(title: nil, message: nil, preferredStyle: preferredStyle)
        alert.setup()
        alert.delegate = self

        self.present(alert, animated: true) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
            alert.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
        }

    }

    private var isKeyboardType = true {
        didSet {
            if isKeyboardType {
                btnSticker.setImage(UIImage(named: "ic_sticker"), for: .normal)
                textView.inputView = nil
                textView.reloadInputViews()
            } else {
                btnSticker.setImage(UIImage(named: "ic_keyboard"), for: .normal)
                textView.inputView = kbStickerView
                textView.reloadInputViews()
            }
        }
    }

    @objc private func btnStickerTapped() {
        isKeyboardType = !isKeyboardType
        if !isKeyboardType {
            textView.becomeFirstResponder()
        }
    }
    fileprivate func setupRecordView() {
        recordButton.recordView = recordView
        recordView.delegate = self
        recorder = AudioRecorder()
    }

    func initialize(user: User, status: Status) {
        self.user = user
        self.status = status
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.placeholderTextView.text = Strings.write_message
        textView.placeholderColor = UIColor.lightGray
        textView.delegate = self

        setupStickerView()
        setupRecordView()


        btnSticker.addTarget(self, action: #selector(btnStickerTapped), for: .touchUpInside)
        showReplyLayout()

        initNetworkManagers()

    }

    private func initNetworkManagers(){
        downloadManager = DownloadManager(disposeBag: disposeBag)
        uploadManager = UploadManager(disposeBag: disposeBag, messageEncryptor: MessageEncryptor(encryptionHelper: EncryptionHelper()))
        requestManager = RequestManager(disposeBag: disposeBag, downloadManager: downloadManager, uploadManager: uploadManager)
    }



    private func setupStickerView() {
        kbStickerView = KBStickerView()
        kbStickerView.translatesAutoresizingMaskIntoConstraints = false
        let stickers = StickerBundleRetriever.getStickersFromBundle().map { Sticker (data: $0.path, resourceType: .assets) }


        let stickerCategories = [
            StickerCategory(stickers: stickers, icon: "ic_sticker_small", iconResourceType: .assets)
        ]

        let stickerProvider = StickerProvider(stickerCategories: stickerCategories, stickerDelegate: self, recentsEnabled: true)
        kbStickerView.stickerProvider = stickerProvider

    }

    fileprivate func showReplyLayout() {

        let type = status.type

        //check if view has been initialized
        if replyUserName == nil{
            return
        }
        
        replyUserName.text = user.properUserName
        
        replyDescTitle.text = StatusHelper.getStatusContent(status: status)
        replyIcon.isHidden = type == .text


        if type == .image || type == .video {
            replyThumb.isHidden = false
            replyThumb.image = status.thumbImg.toUIImage()
        } else {
            replyThumb.isHidden = true
        }



        replyIcon.image = UIImage(named: StatusHelper.getStatusTypeImageName(statusType: type))

        textView.becomeFirstResponder()


    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let controller = segue.destination as? CameraVCViewController {
            Permissions.requestCameraPermissions(completion: { isAuthorized in
                if isAuthorized {
                    controller.delegate = self
                }
            })

        }
    }

    func sendMessage(textMessage: String) {

        //if message is too long show a message and prevent the user from sending it
        if textMessage.lengthOfBytes(using: .utf8) > FireConstants.MAX_SIZE_STRING {
            showAlert(type: .error, message: Strings.message_is_too_big)
            return
        }

        if textMessage.isEmpty {
            return
        }

        let message = MessageCreator(user: user, type: .SENT_TEXT, appRealm: appRealm).quotedMessage(getQuotedMessage()).text(textMessage).build()

        textView.clear()
        

        requestManager.request(message: message, callback: nil, appRealm: appRealm)


        //set the button back to Record
        recordButton.animate(state: .toRecord)

    }


    //isFromCamera is used to determine whether to delete the source file,since it will be saved in 'tmp' directory.
    func sendVideo(video: AVPlayerItem?, isFromCamera: Bool) {
        guard let videoItem = video, let assetUrl = videoItem.asset as? AVURLAsset else {
            return
        }


        let videoExt = assetUrl.url.pathExtension
        let outputUrl = DirManager.generateFile(type: .SENT_VIDEO)
        //if it's not an MP4 Video we need to convert it to MP4 so Androdi Devices can play the Video
        //since MOV files are not supported on Android
        if videoExt != "mp4" {
            VideoUtil.exportAsMp4(inputUrl: assetUrl.url, outputUrl: outputUrl) {

                DispatchQueue.main.async {
                    let message = MessageCreator(user: self.user, type: .SENT_VIDEO, appRealm: appRealm).quotedMessage(self.getQuotedMessage()).path(outputUrl.path).copyVideo(false, deleteVideoOnComplete: false).build()
                    //
                    //delete VideoFile if it was saved directly from Camera (tmp directory)


                    self.uploadManager.upload(message: message, callback: nil, appRealm: appRealm)

                    if isFromCamera {
                        try? assetUrl.url.deleteFile()
                    }



                    self.replyFinished()

                }

            }

        } else {
            let message = MessageCreator(user: user, type: .SENT_VIDEO, appRealm: appRealm).quotedMessage(getQuotedMessage()).path(assetUrl.url.path).copyVideo(true, deleteVideoOnComplete: isFromCamera).build()

            uploadManager.upload(message: message, callback: nil, appRealm: appRealm)

            self.replyFinished()

        }




    }

    private func sendImage(data: Data, previewImage: UIImage? = nil) {

        let message = MessageCreator(user: user, type: .SENT_IMAGE, appRealm: appRealm).quotedMessage(getQuotedMessage()).image(imageData: data, thumbImage: previewImage).build()



        requestManager.request(message: message, callback: nil, appRealm: appRealm)

        replyFinished()
    }

    private func sendSticker(stickerPath: String) {
        let message = MessageCreator(user: user, type: .SENT_STICKER, appRealm: appRealm).quotedMessage(getQuotedMessage()).path(stickerPath).build()



        requestManager.request(message: message, callback: nil, appRealm: appRealm)

        replyFinished()
    }



    func getQuotedMessage() -> Message {
        return StatusHelper.statusToMessage(status: status, userId: user.uid)
    }


    //dismiss reply layout
    @objc private func replyFinished() {
        self.dismiss(animated: true, completion: nil)
        showAlert(type: .notice, message: Strings.sending_reply)
    }



}


extension ReplyStatusVC: UITextViewDelegate, GrowingTextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {



        let text = textView.text.trim()


        if text.isEmpty {
            recordButton.animate(state: .toRecord)
        } else {
            recordButton.animate(state: .toSend)
        }

        if !hasLayout {
            let textViewHeight = textView.frame.height

            updateBottomConstraint(textViewHeight: textViewHeight)
            hasLayout = true
        }

    }

    private func updateBottomConstraint(textViewHeight: CGFloat) {
        let font = textView.font!
        let numLines = Int((textView.contentSize.height / font.lineHeight))

        let bottomMargin = numLines == 1 ? textViewHeight + defaultTypingViewBottomConstraint : textViewHeight

        typingViewBottomConstraint.constant = bottomMargin
    }

    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
        updateBottomConstraint(textViewHeight: height)
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }




    }

}
extension ReplyStatusVC: MTImagePickerControllerDelegate {


    // Implement it when setting source to MTImagePickerSource.Photos
    func imagePickerController(picker: MTImagePickerController, didFinishPickingWithPhotosModels models: [MTImagePickerPhotosModel]) {


        for model in models {

//            //check if it's an image or a video
            if model.mediaType == .Photo {
                model.getImageAsyncData { data in
                    if let data = data {
                        self.sendImage(data: data, previewImage: model.getThumbImage(size: CGSize(width: 50, height: 50))!)
                    }

                }
            } else {


                model.fetchAVPlayerItemAsync(complete: { (playerItem) in
                    if let video = playerItem {
                        DispatchQueue.main.async {
                            self.sendVideo(video: video, isFromCamera: false)
                        }

                    }
                })


            }

        }



    }




    private func sendVoiceMessage(duration: CGFloat) {


        let message = MessageCreator(user: user, type: .SENT_VOICE_MESSAGE, appRealm: appRealm).quotedMessage(getQuotedMessage()).path(recorder.url.path).duration(duration.fromatSecondsFromTimer()).build()


        requestManager.request(message: message, callback: nil, appRealm: appRealm)


        replyFinished()
        recorder.releaseAudioRecorder()

    }

}



extension ReplyStatusVC: RecordViewDelegate {

    func onStart() {


        self.recorder.start()
        self.typingViewContainer.isHidden = true
        self.recordView.isHidden = false


        if !hasLayout {
            let textViewHeight = textView.frame.height
            updateBottomConstraint(textViewHeight: textViewHeight)
            hasLayout = true
        }


    }

    func onCancel() {

        recorder.stop()
        do {
            try recorder.url.deleteFile()
        } catch {

        }


    }

    func onFinished(duration: CGFloat) {
        recordView.isHidden = true
        typingViewContainer.isHidden = false

        recorder.stop()
        if duration < 1 {
            do {
                try recorder.url.deleteFile()
            } catch {

            }
        } else {
            sendVoiceMessage(duration: duration)
        }

    }

    func onAnimationEnd() {
        recordView.isHidden = true
        typingViewContainer.isHidden = false

    }
}


extension ReplyStatusVC: ChooseActionAlertDelegate {
    fileprivate func sendLocation(_ mLocation: Location) {


        LocationImageExtractor.getMapImage(location: mLocation.location) { (mapImage) in
            guard let mapImage = mapImage else {
                return
            }

            let message = MessageCreator(user: self.user, type: .SENT_LOCATION, appRealm: appRealm).quotedMessage(self.getQuotedMessage()).location(mLocation.toRealmLocation(), mapImage: mapImage).build()



            self.uploadManager.sendMessage(message: message, callback: nil, appRealm: appRealm)

            self.replyFinished()
        }



    }

    func didClick(clickedItem: ClickedItem) {
        switch clickedItem {
        case .image:
            Permissions.requestPhotosPermissions { (isAuthorized) in
                if isAuthorized {
                    let imagePicker = ImagePickerRequest.getRequest(delegate: self)
                    self.present(imagePicker, animated: true, completion: nil)
                }
            }

            break

        case .camera:
            Permissions.requestCameraPermissions { (isAuthorized) in
                if isAuthorized {
                    self.performSegue(withIdentifier: "toCamera", sender: nil)

                }
            }
            break

        case .contact:

            Permissions.requestContactsPermissions { (isAuthorized) in
                if isAuthorized {
                    let contactPicker = ContactsPicker(delegate: self, multiSelection: true, subtitleCellType: .phoneNumber)
                    let navigationController = UINavigationController(rootViewController: contactPicker)
                    self.present(navigationController, animated: true, completion: nil)
                }
            }


            break

        case .location:
            let locationPicker = LocationPickerViewController()

            // button placed on right bottom corner
            locationPicker.showCurrentLocationButton = true // default: true

            // default: navigation bar's `barTintColor` or `.whiteColor()`
            locationPicker.currentLocationButtonBackground = .blue

            // ignored if initial location is given, shows that location instead
            locationPicker.showCurrentLocationInitially = true // default: true

            locationPicker.mapType = .standard // default: .Hybrid

            // for searching, see `MKLocalSearchRequest`'s `region` property
            locationPicker.useCurrentLocationAsHint = true // default: false

            // optional region distance to be used for creation region when user selects place from search results
            locationPicker.resultRegionDistance = 500 // default: 600

            locationPicker.completion = { location in

                // do some awesome stuff with location
                guard let mLocation = location else {
                    return
                }


                self.sendLocation(mLocation)
            }

            self.present(locationPicker, animated: true)

            break

        }
    }
}


extension ReplyStatusVC: ContactsPickerDelegate {

    fileprivate func sendContacts(contacts: [Contact]) {

        for contact in contacts {
            if contact.phoneNumbers.isNotEmpty {
                let message = MessageCreator(user: self.user, type: .SENT_CONTACT, appRealm: appRealm).quotedMessage(self.getQuotedMessage()).contact(contact.toRealmContact()).build()


                uploadManager.sendMessage(message: message, callback: nil, appRealm: appRealm)

            }
        }


        self.replyFinished()
    }

    func contactPicker(_: ContactsPicker, didSelectMultipleContacts contacts: [Contact]) {
        dismiss(animated: true, completion: nil)
        if contacts.isEmpty {
            return
        }


        
        let alert = properAlert(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "\(Strings.share) \(contacts.count) \(Strings.contacts)", style: .default, handler: { (_) in
            self.sendContacts(contacts: contacts)
        }))

        alert.addAction(UIAlertAction(title: Strings.cancel, style: .default, handler: nil))

        self.present(alert, animated: true) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertController))
            alert.view.superview?.subviews[0].addGestureRecognizer(tapGesture)
        }

    }

    @objc private func dismissAlertController() {
        self.dismiss(animated: true, completion: nil)
    }

    func contactPicker(_: ContactsPicker, didContactFetchFailed error: NSError) {

    }

    func contactPickerDidCancel(_: ContactsPicker) {
        dismiss(animated: true, completion: nil)
    }
}

extension ReplyStatusVC: CameraResult {



    //this is called when user takes a video from the Camera
    func videoTaken(videoUrl: URL) {
        let playerItem = AVPlayerItem(asset: AVAsset(url: videoUrl))
        sendVideo(video: playerItem, isFromCamera: true)
    }
    //this is called when user takes a photo from the Camera
    func imageTaken(image: UIImage?) {
        if let image = image, let data = image.toData(.highest) {
            sendImage(data: data)



        }
    }

}


extension ReplyStatusVC: StickerProviderDelegate {
    func willLoadSticker(imageView: UIImageView, sticker: Sticker) {

        if sticker.resourceType == .assets {
            let stickerData = sticker.data
            let stickerImage = UIImage(named: stickerData)
            imageView.image = stickerImage
        }
    }

    func willLoadStickerCategory(imageView: UIImageView, stickerCategory: StickerCategory, selected: Bool) {
        if stickerCategory.iconResourceType == .assets {
            let icon = stickerCategory.icon
            imageView.image = UIImage(named: icon)
        }
    }

    func didChangePage(category: StickerCategory) {

    }

    func didClickSticker(sticker: Sticker) {
        sendSticker(stickerPath: sticker.data)
    }
}
