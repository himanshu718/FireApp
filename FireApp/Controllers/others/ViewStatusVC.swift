//
//  ViewStatusVC.swift
//  FireApp
//
//  Created by Devlomi on 10/28/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation
import AVKit
import Kingfisher
import Hero
import RxSwift
import BottomPopup

class ViewStatusVC: BaseVC {

    let imageDuration: TimeInterval = 7
    let textDuration: TimeInterval = 6

    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var segmentedProgressView: SegmentedProgressBar!

    @IBOutlet weak var textStatusTextView: UITextView!
    
    @IBOutlet weak var btnSeenByArow:UIButton!
    @IBOutlet weak var seenByCountLbl:UILabel!
    @IBOutlet weak var tapToShowSeenByView:UIView!
    @IBOutlet weak var btnReply:UIButton!
    @IBOutlet weak var replyView:UIView!
    
    


    var user:User!
    


    private var videoLayer: AVPlayerLayer?
    private var player: AVPlayer?

    private var userStatuses: UserStatuses!

    private var statuses: [Status]!

    private var currentIndex = 0

    private var panGR: UIPanGestureRecognizer!
    
    
    private lazy var statusSeenByVC:StatusSeenByVC={
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "statusSeenByVC") as! StatusSeenByVC
    }()


    private lazy var replyStatusVC:ReplyStatusVC={
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "replyStatusVC") as! ReplyStatusVC
    }()


    private var videoDownloadSingle: Single<String>?

    fileprivate func initSegementedProgressBar() {
        segmentedProgressView.delegate = self

        segmentedProgressView.numberOfSegments = statuses.count
        segmentedProgressView.topColor = .white
        segmentedProgressView.durations = getDurations()

        segmentedProgressView.isPaused = true


    }
    
    

    fileprivate func initGestureRecognizers() {
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGR.delegate = self

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:))))


        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(viewLongTapped(_:))))
        view.addGestureRecognizer(panGR)
        
        btnSeenByArow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showSeenByViewTapped)))
        tapToShowSeenByView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showSeenByViewTapped)))
        
        
        btnReply.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(replyViewTapped)))
        replyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(replyViewTapped)))
    }

    fileprivate func setInitialStautsPlaceholders(_ status: Status) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        view.backgroundColor = .black

        previewImage.isHidden = false
        loadingView.isHidden = false
        textStatusTextView.isHidden = true
        segmentedProgressView.isPaused = true
        videoLayer?.removeFromSuperlayer()
        timeLbl.text = TimeHelper.getMediaTime(timestamp: status.timestamp.toDate())
        player?.pause()
        //load thumb blurred image while loading original image or video
        if (status.type == .image || status.type == .video) {
            previewImage.image = status.thumbImg.toUIImage().blurred(blurValue: 35)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()



        //resize loadingView
        self.loadingView.transform = CGAffineTransform(scaleX: 2, y: 2)


        
        userImage.hero.id = user.uid


        userImage.image = user.thumbImg.toUIImage()
        userNameLbl.text = user.uid == FireManager.getUid() ? Strings.you : user.userName


        view.bringSubviewToFront(tapToShowSeenByView)
        view.bringSubviewToFront(tapToShowSeenByView)

        statusSeenByVC.popupDelegate = self
        replyStatusVC.popupDelegate = self
        
 
        
        

        replyStatusVC.initialize(user:user,status:statuses.first!)
        
        initSegementedProgressBar()


        initGestureRecognizers()


        if let status = statuses.first {

            setInitialStautsPlaceholders(status)

        }
        
        
        if user.uid == FireManager.getUid(){
            replyView.isHidden = true
            tapToShowSeenByView.isHidden = false
        }else{
            replyView.isHidden = false
            tapToShowSeenByView.isHidden = true
        }
        





    }
    
    @objc private func showSeenByViewTapped(){
        present(statusSeenByVC, animated: true, completion: nil)
    }
    
    @objc private func replyViewTapped(){
        present(replyStatusVC, animated: true, completion: nil)
    }



    private func setStatusAsSeenIfNeeded(status: Status) {
        let userId = status.userId
        //set status as seen
        if !status.isSeen {
            RealmHelper.getInstance(appRealm).setStatusAsSeen(statusId: status.statusId)
            //check if all statuses are seen and save it
            if let lastStatus = statuses.last, status.statusId == lastStatus.statusId {
                RealmHelper.getInstance(appRealm).setAllStatusesAsSeen(userId: userId)
            }
        }
        //Schedule a job to update status count on Firebase
        if status.userId != FireManager.getUid() && !status.seenCountSent {
            StatusManager.setStatusSeen(uid: status.userId, statusId: status.statusId).subscribe().disposed(by: disposeBag)
        }
    }

    @objc private func playerDidFinishPlaying() {
        segmentedProgressView.skip()
    }

    //get the tapped portion. left,middle,right
    @objc private func viewTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)

        let locationX = location.x



        let viewWidth = view.bounds.width

        let partWidth = viewWidth / 3

        let leftPart = partWidth
        let middlePart = partWidth * 2
        let rightPart = partWidth * 3


        if locationX <= leftPart {
            segmentedProgressView.rewind()
            //left part tapped
        } else if locationX > middlePart && locationX <= rightPart {
            segmentedProgressView.skip()
            //right part tapped

        } else {
            //middle part tapped

        }


    }

    @objc private func viewLongTapped(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
          pauseStatus()
        } else if sender.state == .ended {
         resumeStatus()
        }

    }
    
    private func pauseStatus(){
        segmentedProgressView.isPaused = true
        if statuses[currentIndex].type == .video {
            player?.pause()
        }
    }
    
    private func resumeStatus(){
        segmentedProgressView.isPaused = false
        if statuses[currentIndex].type == .video {
            player?.play()
        }
    }

    private func loadStatus(status: Status) {

        setInitialStautsPlaceholders(status)

        if status.type == .video {
            loadVideo(status: status)
        } else if status.type == .image {
            loadImage(status: status)
        } else {
            loadTextStatus(status: status)
            updateTextFont()
        }

        let statusSeenByList = RealmHelper.getInstance(appRealm).getSeenByList(seenByList: status.statusSeenBy)
        statusSeenByVC.statusSeenByArray = Array(statusSeenByList)
        seenByCountLbl.text = "\(statusSeenByList.count)"
        setStatusAsSeenIfNeeded(status: status)
        updateBottomSheet(status: status)
        replyStatusVC.updateStatus(status)
    }
    
    private func updateBottomSheet(status:Status){
        StatusManager.getStatusSeenByList(statusId: status.statusId).subscribe { (statusId,statusSeenByArray) in
            let currentStatus = self.statuses[self.currentIndex]
            if statusId == currentStatus.statusId{
                self.statusSeenByVC.statusSeenByArray = statusSeenByArray
                self.seenByCountLbl.text = "\(statusSeenByArray.count)"
            }
        } onError: { (error) in
            
        }.disposed(by: disposeBag)

    }

    private func loadTextStatus(status: Status) {
        if let textStatus = status.textStatus {


            loadingView.isHidden = true
            previewImage.isHidden = true

            textStatusTextView.isHidden = false

            let customFont = UIFont.getFontByFileName(textStatus.fontName)
            textStatusTextView.font = customFont


            textStatusTextView.text = textStatus.text
            view.backgroundColor = textStatus.backgroundColor.toUIColor()
            segmentedProgressView.isPaused = false
        }
    }

    //load image remotely and cache it using Kingfisher
    fileprivate func loadRemoteImage(_ url: URL?) -> DownloadTask? {
        return previewImage.kf.setImage(with: url) { result in
            switch result {
            case .success(let value):
                self.loadingView.isHidden = true
                self.segmentedProgressView.isPaused = false
            case .failure(let error):
                self.showAlert(type: .error, message: Strings.error)
            }
        }
    }

    private func loadImage(status: Status) {

        //if this status by this user load it locally ,otherwise load it from server and cache it
        var url: URL!

        if status.localPath == "" {
            url = URL(string: status.content)
            loadRemoteImage(url)

        } else {
            url = URL(fileURLWithPath: status.localPath)
            loadingView.isHidden = true
            self.segmentedProgressView.isPaused = false
            previewImage.image = UIImage(contentsOfFile: status.localPath)
        }


    }

    fileprivate func playVideo(filePath: String) {
        let videoURL = URL(fileURLWithPath: filePath)

        player = AVPlayer(url: videoURL)

        let playerController = AVPlayerViewController()
        playerController.player = player
        videoLayer = AVPlayerLayer(player: player)
        videoLayer?.frame = view.bounds

        view.layer.insertSublayer(videoLayer!, at: 0)
        player?.play()
        segmentedProgressView.isPaused = false
        previewImage.isHidden = true
        loadingView.isHidden = true

        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    private func loadVideo(status: Status) {


        let filePath = status.localPath


        //if the video is not exists download it
        if status.localPath == "" {

            downloadStatusVideo(status: status)
        } else {
            //if the video is exists in device play it
            if FileManager.default.fileExists(atPath: filePath) {

                playVideo(filePath: filePath)
            } else {
                //otherwise download it
                downloadStatusVideo(status: status)
            }
        }



    }

    private func downloadStatusVideo(status: Status) {
        videoDownloadSingle = StatusManager.downloadVideoStatus(id: status.statusId, url: status.content, statusType: status.type)
        videoDownloadSingle?.subscribe(onSuccess: { (path) in
            self.playVideo(filePath: path)
        }, onError: { (error) in
                self.showAlert(type: .error, message: Strings.error)
            }).disposed(by: disposeBag)
    }



    private func getDurations() -> [TimeInterval] {
        var durations = [TimeInterval]()

        for status in statuses {
            if status.type == .image {
                durations.append(imageDuration)
            } else if status.type == .text {
                durations.append(textDuration)
            } else {
                //if it's a video set its duration to the video duration
                durations.append(Double(status.duration) / 1000.0)
            }
        }
        return durations

    }
    @objc func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / view.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: previewImage)

        default:
            if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }



    public func initialize(userStatuses: UserStatuses) {
        self.userStatuses = userStatuses
        self.user = userStatuses.user
        statuses = Array(userStatuses.statuses)
    }
    
    public func initialize(statuses: [Status],user:User) {
        self.statuses = statuses
        self.user = user
    }
    
    
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.segmentedProgressView.startAnimation()
            self.loadStatus(status: self.statuses.first!)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    private func updateTextFont() {
        if (textStatusTextView.text.isEmpty || textStatusTextView.bounds.size.equalTo(.zero)) {
            return
        }

        let textViewSize = textStatusTextView.frame.size;
        let fixedWidth = textViewSize.width - 200.0
        let expectSize = textStatusTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))) ;

        var expectFont = textStatusTextView.font;
        if (expectSize.height > textViewSize.height) {
            while (textStatusTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                expectFont = textStatusTextView.font!.withSize(textStatusTextView.font!.pointSize - 1)
                textStatusTextView.font = expectFont
            }
        }
        else {
            while (textStatusTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                expectFont = textStatusTextView.font;
                textStatusTextView.font = textStatusTextView.font!.withSize(textStatusTextView.font!.pointSize + 1)
            }
            textStatusTextView.font = expectFont;
        }
    }

}
extension ViewStatusVC: SegmentedProgressBarDelegate {
    func segmentedProgressBarChangedIndex(index: Int) {
        currentIndex = index
        //fix for out of bounds when status is deleted
        if index >= 0 && index < statuses.count{
        loadStatus(status: statuses[index])
        }
    }

    func segmentedProgressBarFinished() {
        navigationController?.popViewController(animated: true)
    }


}
extension ViewStatusVC: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            let v = panGR.velocity(in: nil)
            return v.y > abs(v.x)
        }
        return false
    }
}


extension ViewStatusVC:BottomPopupDelegate{
    func bottomPopupWillAppear() {
        pauseStatus()
    }
    
    func bottomPopupWillDismiss() {
        resumeStatus()
    }
}
