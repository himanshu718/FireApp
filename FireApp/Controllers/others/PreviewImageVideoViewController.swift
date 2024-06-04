//
//  PreviewImageVideoViewController.swift
//  FireApp
//
//  Created by Devlomi on 7/13/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Hero
import AVKit


class PreviewImageVideoViewController: BaseVC, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, VideoPlayerDelegate, MediaPreviewDelegate {

    var playerCurrentState: VideoStatus = .stopped

    private var list: Results<Message>!
    private var chatId: String?
    private var user: User!

    private var currentItemPosition = 0

    private var panGR = UIPanGestureRecognizer()
    private var messageId: String!



    private var selectedIndex: IndexPath? {
        didSet {
            currentItemPosition = self.selectedIndex!.row
        }
    }

    private var messageTimeLbl, userNameLbl: UILabel!
    private var mediaIndex: IndexPath?
    private var hideViewsWork: DispatchWorkItem?

    //update lbls depending on progress
    func didUpdate(currentProgress: CMTime, duration: CMTime?) {
        guard let videoDuration = duration else {
            return
        }


        startTimeLbl.text = currentProgress.seconds.timeFormat()
        endTimeLbl.text = duration?.seconds.timeFormat()


        self.videoSlider.value = Float(currentProgress.seconds / videoDuration.seconds)
    }

    func didStatusChange(status: VideoStatus) {
        let isHidden = status == .playing
        playerCurrentState = status
        hideViewsAfterSometime(hide: isHidden)
        hideViewsWork?.cancel()
     
    }

    //hide or show views when playing a video
    func mainViewTapped() {
        if playerCurrentState != .playing {
            return
        }
        let hide = toolbar.alpha == 1

        hideViewsAfterSometime(hide: hide)
        if !hide {
            scheduleHideViewsWork()
        }
    }

    //hide views automatically after 2 secs
    private func scheduleHideViewsWork() {
        hideViewsWork?.cancel()
        hideViewsWork = DispatchWorkItem(block: {
            self.hideViewsAfterSometime(hide: true)

        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: hideViewsWork!)
    }

    private func hideOrShowVideoViews(hide: Bool) {
        videoDurationContainer.isHidden = hide
        toolbar.isHidden = hide
        self.navigationController?.isNavigationBarHidden = hide
        getPlayBtnFromCell()?.isHidden = hide
    }

    private func getPlayBtnFromCell() -> UIButton? {
        if collectionView.visibleCells.isEmpty {
            return nil
        }
        if let cell = collectionView.visibleCells[0] as? PreviewImageCollectionViewCell {
            return cell.playBtn
        }
        return nil
    }

    public func initialize(chatId: String, user: User, messageId: String) {
        self.chatId = chatId
        self.user = user
        self.messageId = messageId


    }

    private func hideViewsAfterSometime(hide: Bool) {
        stopAnimation()

        UIView.animate(withDuration: 0.2, animations: {
            let alpha: CGFloat = hide ? 0 : 1.0
            self.setVideoViewsAlpha(alpha: alpha)

        }) { _ in
            self.hideOrShowVideoViews(hide: hide)
        }
    }

    private func setVideoViewsAlpha(alpha: CGFloat) {
        self.videoDurationContainer.alpha = alpha
        self.navigationController?.navigationBar.alpha = alpha
        self.toolbar.alpha = alpha
        getPlayBtnFromCell()?.alpha = alpha
    }

    private func stopAnimation() {
        self.videoDurationContainer.layer.removeAllAnimations()
        self.toolbar.layer.removeAllAnimations()
        self.navigationController?.navigationBar.layer.removeAllAnimations()
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var videoDurationStackView: UIStackView!
    @IBOutlet weak var videoDurationContainer: UIView!
    @IBOutlet weak var startTimeLbl: UILabel!
    @IBOutlet weak var endTimeLbl: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!



    @IBAction func trashTapped(_ sender: Any) {
        let alert = UIAlertController(title: Strings.confirmation, message: Strings.deleteItemConfirmation, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.no, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: Strings.yes, style: .destructive, handler: { action in
            if let message = self.list.getItemSafely(index: self.currentItemPosition) as? Message {

                RealmHelper.getInstance(appRealm).deleteMessages(messages: [message])
                self.collectionView.deleteItems(at: [IndexPath(row: self.currentItemPosition, section: 0)])
                //close this View if there are no other items
                if self.list.isEmpty {
                    self.dismiss(animated: true, completion: nil)
                }
            }

        }))
        self.present(alert, animated: true, completion: nil)

    }

    @IBAction func shareTapped(_ sender: Any) {
        guard let selectedItem = list.getItemSafely(index: currentItemPosition) as? Message else {
            return
        }

        let shareItem = URL(fileURLWithPath: selectedItem.localPath)


        let activityViewController = UIActivityViewController(activityItems: [shareItem], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash


        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)

    }



    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return list.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(indexPath: indexPath) as PreviewImageCollectionViewCell

        cell.delegate = self

        guard let message = list.getItemSafely(index: indexPath.row) as? Message else {
            return cell
        }

        cell.bind(message: message, viewBounds: view.bounds)
        if (message.typeEnum == .SENT_VIDEO || message.typeEnum == .RECEIVED_VIDEO) {
            endTimeLbl.text = message.mediaDuration
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()

        visibleRect.origin = collectionView.contentOffset
        visibleRect.size = collectionView.bounds.size

        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)

        guard let indexPath = collectionView.indexPathForItem(at: visiblePoint) else {
            return
        }

        //listen only for new item changes
        if currentItemPosition == indexPath.row {
            return
        }



        currentItemPosition = indexPath.row

        hideViewsWork?.cancel()
        hideOrShowVideoViews(hide: false)
        videoDurationContainer.isHidden = true
        setVideoViewsAlpha(alpha: 1.0)
        playerCurrentState = .stopped


        setNavBarData()
        setDurationData()








    }

    private func setNavBarData() {

        if let message = list.getItemSafely(index: currentItemPosition) as? Message {
            let date = TimeHelper.getMediaTime(timestamp: message.timestamp.toDate())
            messageTimeLbl.text = date
            userNameLbl.text = getSenderName(message: message, user: user)
        }

    }

    private func getSenderName(message: Message, user: User) -> String {
        if message.fromId == FireManager.getUid() {
            return Strings.you
        }
        if user.isGroupBool, let group = user.group {
            if let foundUser = group.users.filter({ $0.uid == message.fromId }).first {
                return getUserNameOrPhone(user: foundUser)
            }
            return ""
        }

        return user.userName
    }

    //return Phone number if user name is not exist
    //since a user maybe removed from a group
    private func getUserNameOrPhone(user: User) -> String {
        if (user.userName == "") {
            return user.phone
        }
        return user.userName
    }

    private func setDurationData() {
        videoSlider.setValue(0, animated: false)
        startTimeLbl.text = "0:00"
        if let message = list.getItemSafely(index: currentItemPosition) as? Message {
            endTimeLbl.text = message.mediaDuration
        }

    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let videoCell = cell as? PreviewImageCollectionViewCell {
            videoCell.stopVideo()


        }

    }
    override func viewDidLoad() {
        super.viewDidLoad()

        list = RealmHelper.getInstance(appRealm).getMediaInChat(chatId: chatId!)


        initCollectionView()

        panGR.addTarget(self, action: #selector(pan))
        panGR.delegate = self


        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.allMedia, style: .plain, target: self, action: #selector(goToAllMedia))

        addTimeAndUserLabels()

        setNavBarData()

        setDurationData()


        videoSlider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)

        hideViewsWork?.cancel()
        hideOrShowVideoViews(hide: false)
        videoDurationContainer.isHidden = true
        setVideoViewsAlpha(alpha: 1.0)
        playerCurrentState = .stopped

    }

    private func initCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true

        if let index = list.firstIndex(where: { $0.messageId == messageId }) {
            currentItemPosition = index
            selectedIndex = IndexPath(item: currentItemPosition, section: 0)
        }

        view.layoutIfNeeded()
        collectionView.reloadData()
        if let selectedIndex = selectedIndex {
            collectionView.scrollToItem(at: selectedIndex, at: .centeredHorizontally, animated: false)
        }


        collectionView.addGestureRecognizer(panGR)
        collectionView.isPrefetchingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)

    }
    private func addTimeAndUserLabels() {

        userNameLbl = UILabel()
        messageTimeLbl = UILabel()
        messageTimeLbl.font = messageTimeLbl.font.withSize(12)

        let stackView = UIStackView(arrangedSubviews: [userNameLbl, messageTimeLbl])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4

        navigationItem.titleView = stackView
    }


    @objc private func handleSliderChange () {
        if let cell = collectionView?.visibleCells[0] as? PreviewImageCollectionViewCell, let player = cell.player, let duration = player.currentItem?.asset.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(videoSlider.value) * totalSeconds
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player.seek(to: seekTime, completionHandler: { (completedSeek) in
                //perhaps do something later here
            })
        }


    }
    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    @objc func goToAllMedia() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

        let mediaVc = storyBoard.instantiateViewController(withIdentifier: "MediaPreviewVC") as! MediaPreviewVC
        mediaVc.initialize(chatId: chatId!)
        mediaVc.delegate = self


        navigationController?.pushViewController(mediaVc, animated: true)
    }

    //swipe down to dismiss
    @objc func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / collectionView!.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            if let cell = collectionView?.visibleCells[0] as? PreviewImageCollectionViewCell {
                let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
                Hero.shared.apply(modifiers: [.position(currentPos)], to: cell.previewImage)
            }
        default:
            if progress + panGR.velocity(in: nil).y / collectionView!.bounds.height > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        if let cell = collectionView.visibleCells[0] as? PreviewImageCollectionViewCell {
            cell.stopVideo()
        }


    }

 


    func didPop(chatId: String, user: User, selectedIndex: IndexPath, currentItemPosition: Int) {
        initialize(chatId: chatId, user: user, messageId: messageId)
        collectionView.scrollToItem(at: selectedIndex, at: .centeredHorizontally, animated: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
    }

}





extension PreviewImageVideoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let v = panGR.velocity(in: nil)
        return v.y > abs(v.x)

    }

}



