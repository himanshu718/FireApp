//
//  CallingVC.swift
//  FireApp
//
//  Created by Devlomi on 11/9/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import AgoraRtcKit


class CallingVC: BaseVC {

    let enabledColor = "#a2d5fa".toUIColor()

    @IBOutlet weak var remoteView: CallingGridView!
    @IBOutlet weak var localView: UIView!

    @IBOutlet weak var bottomButtonsStack: UIStackView!
    @IBOutlet weak var btnFlipCamera: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnVideo: UIButton!
    @IBOutlet weak var btnMic: UIButton!

    @IBOutlet weak var btnHangup: UIButton!



    @IBOutlet weak var callTypeLbl: UILabel!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var callStateLbl: UILabel!
    @IBOutlet weak var userImg: UIImageView!

    @IBOutlet weak var topViewContainer: UIView!
    @IBOutlet weak var bottomViewContainer: UIView!

    @IBOutlet weak var topViewTopCnstraint: NSLayoutConstraint!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomViewBottomCnstraint: NSLayoutConstraint!

    private var user: User?
    private var uid: String = ""
    private var phoneNumber: String = ""
    private var conferenceId: String = ""
    private var callDirection: CallDirection = .OUTGOING
    private var callType: CallType = .VOICE
    private var callingState: CallingState = .NONE {
        didSet {

            switch callingState {

            case .ANSWERED:
                callStateLbl.text = Strings.answered
                break

            case .CONNECTED:
                callStateLbl.text = Strings.waiting_for_answer
                break

            case .CONNECTING:
                callStateLbl.text = Strings.connecting
                break

            case .FAILED:
                callStateLbl.text = Strings.failed
                break

            case .RECONNECTING:
                callStateLbl.text = Strings.reconnecting
                break

            default:
                callStateLbl.text = ""
            }
        }
    }
    private var isVideo = false
    private var isIncoming = false

    private var usersUids = [UInt: Bool]()
    private var videoUids = [UInt: (UIView, Bool)]()
    private var hasAnswered = false
    private let fireCallsManager = FireCallsManager()

    private let agoraKit = AppDelegate.shared.agoraKit!

    private var callDuration = 0


    var fireCall: FireCall!

    private var isLocalVideoEnabled: Bool = false {
        didSet {
            updateUI()
            let backgroundColor = isLocalVideoEnabled ? enabledColor : .clear
            btnVideo.backgroundColor = backgroundColor

            btnFlipCamera.isHidden = !isLocalVideoEnabled
            btnSpeaker.isHidden = isLocalVideoEnabled


        }
    }

    private var isRemoteViewEnabled: Bool = false {
        didSet {

            hideOrShowTopViewContainer(hide: isRemoteViewEnabled)
            updateUI()
        }
    }



    private var topLayoutSpacing: CGFloat = 0 {
        didSet {
//            topViewTopCnstraint.constant = topLayoutSpacing
//            UIView.animate(withDuration: 0.2) {
//                self.view.layoutIfNeeded()
//            }

            hideOrShowTopViewContainer(hide: isRemoteViewEnabled)
        }

    }

    private var bottomLayoutSpacing: CGFloat = 0 {
        didSet {

            bottomViewBottomCnstraint.constant = bottomLayoutSpacing

            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }


    private var timerDisposable: Disposable?
    private var timeoutDisposable: Disposable?
    private final let timeout = 30

    
    private var proivderDelegate: ProviderDelegate!




     var isMuted: Bool = false {
        didSet {

            proivderDelegate.setMute(mute: isMuted)
            let backgroundColor = isMuted ? enabledColor : .clear
            btnMic.backgroundColor = backgroundColor

        }
    }

    private var isSpeakerEnabled: Bool = false {
        didSet {

            let backgroundColor = isSpeakerEnabled ? enabledColor : .clear
            btnSpeaker.backgroundColor = backgroundColor

            proivderDelegate.setSpeaker(loud: isSpeakerEnabled)




        }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //resume timer if the call was established

//            scheduleTimer()

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        timerDisposable?.dispose()
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        
        proivderDelegate = ProviderDelegate.sharedInstance
        

        if isVideo {
            Permissions.requestMicAndVideoPermissions(completion: nil)
        } else {
            Permissions.requestMicrophonePermissions(completion: nil)
        }

        let callTypeStr = isVideo ? Strings.video_call: Strings.voice_call
        callTypeLbl.text = callTypeStr

        if let user = user {
            userNameLbl.text = user.userName
            callStateLbl.text = Strings.connecting
            if user.userLocalPhoto != "" {
                userImg.image = UIImage(contentsOfFile: user.userLocalPhoto)
            } else {
                userImg.image = user.thumbImg.toUIImage()
            }

            if !user.isGroupBool {

                //fetch the remote user's photo
                FireManager.checkAndDownloadUserPhoto(user: user, appRealm: appRealm).subscribe(onSuccess: { (thumb, image) in
                    self.userImg.image = UIImage(contentsOfFile: image)
                }).disposed(by: disposeBag)

            }


            isLocalVideoEnabled = isVideo


            btnVideo.isHidden = !isVideo



        } else {
            //if the user is not exists in local database we will set the name as phoneNumber
            userNameLbl.text = phoneNumber
            if let user = user, !user.isGroupBool {


                FireManager.fetchUserByUid(uid: uid, appRealm: appRealm).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).subscribe(onNext: { (user) in
                    //update call object when fetching user
                    RealmHelper.getInstance(appRealm).updateUserObjectForCall(uid: user.uid, callId: self.fireCall.callId);


                    self.userNameLbl.text = user.userName

                }).disposed(by: disposeBag)
            }
        }


        btnHangup.addTarget(self, action: #selector(btnHangupTapped), for: .touchUpInside)

        btnMic.addTarget(self, action: #selector(btnMicTapped), for: .touchUpInside)

        btnSpeaker.addTarget(self, action: #selector(btnSpeakerTapped), for: .touchUpInside)

        btnVideo.addTarget(self, action: #selector(btnVideoTapped), for: .touchUpInside)

        btnFlipCamera.addTarget(self, action: #selector(btnFlipCameraTapped), for: .touchUpInside)


        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
        isSpeakerEnabled = isVideo
        isMuted = false
        updateUI()


        startCall(fireCall: fireCall)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    @objc private func viewTapped() {
        if !isVideo {
            return
        }

        btnHangup.hideOrShow()
        bottomViewContainer.hideOrShow()
    }

    @objc private func btnHangupTapped() {
        endCall(reason: .LOCAL_HUNG_UP)
    }

    @objc private func btnFlipCameraTapped() {
        agoraKit.switchCamera()
    }

    @objc private func btnVideoTapped() {
        isLocalVideoEnabled = !isLocalVideoEnabled
        agoraKit.muteLocalVideoStream(!isLocalVideoEnabled)
        if isLocalVideoEnabled {
            addLocalView()
        } else {
            removeLocalView()
        }

    }


    @objc private func btnMicTapped() {
        isMuted = !isMuted
    }

    @objc private func btnSpeakerTapped() {
        isSpeakerEnabled = !isSpeakerEnabled
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func initialize(fireCall: FireCall) {

        self.uid = fireCall.user!.uid
        self.phoneNumber = fireCall.phoneNumber
        self.callType = fireCall.callType
        self.callDirection = fireCall.callDirection
        self.isVideo = fireCall.isVideo
        self.user = fireCall.user!
        self.fireCall = fireCall
        self.isIncoming = fireCall.callDirection == .INCOMING


    }





    private func scheduleTimer() {
        timerDisposable = Observable<Int>.interval(1, scheduler: MainScheduler.instance).subscribe(onNext: { (time) in

            self.callDuration = time

            let formattedTime = time.timeFormat(false)

            self.callStateLbl.text = formattedTime


        })

        timerDisposable?.disposed(by: disposeBag)
    }

    private func updateUI() {

        let isVideo = fireCall.callType.isVideo

        btnSpeaker.isHidden = isVideo
        btnFlipCamera.isHidden = !isVideo
        btnVideo.isHidden = !isVideo


    }

    private func onRemoteVideoChanged() {
        if videoUids.isEmpty || allUsersAreMuted {
            remoteView.isHidden = true
            userImg.isHidden = false
        } else {
            remoteView.isHidden = false
            userImg.isHidden = true
        }
        isRemoteViewEnabled = !remoteView.isHidden
    }

    private func finishVC() {
        if let navigation = self.navigationController {

            navigation.popViewController(animated: true)
        } else {

            self.dismiss(animated: true, completion: nil)
        }

    }

    private func hideOrShowTopViewContainer(hide: Bool) {
        localView.translatesAutoresizingMaskIntoConstraints = false


        if hide {
            topViewContainer.isHidden = true
            topViewHeight.constant = 0
        } else {
            topViewContainer.isHidden = false
            topViewHeight.constant = 100
            localView.topAnchor.constraint(equalTo: topViewContainer.bottomAnchor).isActive = true
        }



        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    private func onCallEstablished() {
        timeoutDisposable?.dispose()
        timeoutDisposable = nil
        scheduleTimer()
        if !isIncoming {
            ProviderDelegate.sharedInstance.reportOutoingConnected(uuid: UUID(uuidString: fireCall.callUUID)!)
       
        }
    }


    private func addLocalView() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = localView
        videoCanvas.renderMode = .hidden
        // Set the local video view.
        agoraKit.setupLocalVideo(videoCanvas)
        localView.isHidden = false
    }

    private func removeLocalView() {
        localView.isHidden = true
        agoraKit.setupLocalVideo(nil)
    }
    private func setupRemoteView(for uid: UInt) {

        guard videoUids[uid] == nil else {
            return
        }



        let videoCanvas = AgoraRtcVideoCanvas()
        let videoView = UIView(frame: self.view.frame)
        videoCanvas.uid = UInt(uid)
        videoCanvas.view = videoView
        videoCanvas.renderMode = .hidden
        // Set the remote video view.
        agoraKit.setupRemoteVideo(videoCanvas)


        addRemoteView(uid: uid, videoView: videoView)


    }

    private func addRemoteView(uid: UInt, videoView: UIView) {
        videoUids[uid] = (videoView, false)
        remoteView.addItem(id: Int(uid), view: videoView)
        onRemoteVideoChanged()
    }



    private func muteOrUnMuteRemoteView(uid: UInt, setMuted: Bool) {

        if let tuple = videoUids[uid] {

            videoUids[uid] = (tuple.0, setMuted)

            if (setMuted) {
                remoteView.removeItem(id: Int(uid))
            } else {
                addRemoteView(uid: uid, videoView: tuple.0)
            }
        }

        onRemoteVideoChanged()

    }

    private func startDefer() {
        if timeoutDisposable == nil {
            timeoutDisposable = Observable.just(()).delay(.seconds(timeout), scheduler: MainScheduler.instance).subscribe(onCompleted: {

                self.endCall(reason: .NO_ANSWER)
            })
            timeoutDisposable?.disposed(by: disposeBag)
        }
    }

    var x:CGFloat = 0
    var y:CGFloat = 0


}



extension CallingVC {


    func startCall(fireCall: FireCall) {

        callingState = .INITIATING

        agoraKit.delegate = self

        if fireCall.isVideo {
            agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration.init(size: AgoraVideoDimension320x240, frameRate: AgoraVideoFrameRate.fps15, bitrate: AgoraVideoBitrateStandard, orientationMode: AgoraVideoOutputOrientationMode.fixedPortrait))
            agoraKit.enableVideo()

            addLocalView()

        } else {
            agoraKit.disableVideo()

        }



        isSpeakerEnabled = fireCall.isVideo

        if !fireCall.callType.isGroupCall {
            listenForEndingCall()
        }

        if !isIncoming{
            RealmHelper.getInstance().saveObjectToRealm(object: fireCall)
        }
        let joinChannelResult = agoraKit.joinChannel(byToken: nil, channelId: fireCall.channel, info: nil, uid: 0)
        
        if joinChannelResult == 0 {
            if !isIncoming {

                startDefer()

                ProviderDelegate.sharedInstance.reportOutgoingStarted(uuid: UUID(uuidString: fireCall.callUUID)!)

                if fireCall.callType.isGroupCall {
                    fireCallsManager.saveOutgoingGroupCallOnFirebase(fireCall: fireCall, groupId: fireCall.user!.uid).subscribe(onSuccess: { (_) in

                    }) { (error) in
                        self.endCall(reason: .ERROR)
                    }.disposed(by: disposeBag)

                } else {

                    fireCallsManager.saveOutgoingCallOnFirebase(fireCall: fireCall, otherUid: fireCall.user!.uid).subscribe(onSuccess: { (_) in

                    }) { (error) in
                        self.endCall(reason: .ERROR)
                    }.disposed(by: disposeBag)



                }

            }
        } else {
            endCall(reason: .ERROR)
        }


    }

    private func listenForEndingCall() {
        fireCallsManager.listenForEndingCall(callId: fireCall.callId, otherUid: fireCall.user!.uid, isIncoming: isIncoming).subscribe(onNext: { (dataSnapshot) in
            if dataSnapshot.exists() {
                self.endCall(reason: .REMOTE_HUNG_UP)
            }
        }, onError: { (error) in

            }).disposed(by: disposeBag)
    }



    private func removeRemoteView(uid: UInt) {
        videoUids.removeValue(forKey: uid)
        remoteView.removeItem(id: Int(uid))

        onRemoteVideoChanged()

    }

    private func endCall(reason: CallEndedReason) {
        timerDisposable?.dispose()
        leaveChannel()
        fireCallsManager.setCallEnded(callId: fireCall.callId, otherUid: fireCall.user!.uid, isIncoming: isIncoming).subscribe().disposed(by: disposeBag)
        ProviderDelegate.sharedInstance.endCall(fireCall: fireCall, reason: reason, duration: callDuration)
        finishVC()
    }

    private func leaveChannel() {
        agoraKit.leaveChannel()
    }



    var allUsersAreMuted: Bool {
        return videoUids.allSatisfy { (uid, tuple) -> Bool in
            return tuple.1
        }
    }
}





extension CallingVC: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {

        DispatchQueue.main.async {

            self.updateUI()
        }

    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async {

            self.hasAnswered = true
            if self.usersUids.isEmpty {
                self.callingState = .ANSWERED
                self.onCallEstablished()
            }

            self.usersUids[uid] = true

        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {

        DispatchQueue.main.async {
            if state == .decoding {
                if reason == .remoteUnmuted {
                    self.muteOrUnMuteRemoteView(uid: uid, setMuted: false)
                } else {
                    self.setupRemoteView(for: uid)
                }
            } else if state == .stopped {
                self.muteOrUnMuteRemoteView(uid: uid, setMuted: true)
            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async {
            self.usersUids.removeValue(forKey: uid)
            self.videoUids.removeValue(forKey: uid)
            self.removeRemoteView(uid: uid)
            self.onRemoteVideoChanged()

            if self.usersUids.isEmpty && !self.fireCall.callType.isGroupCall {
                self.endCall(reason: .REMOTE_HUNG_UP)
            }
        }
    }




    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        switch state {

        case .connected:
            callingState = .CONNECTED
            break

        case .connecting:
            callingState = .CONNECTING
            break

        case .failed:
            callingState = .FAILED
            break

        case .reconnecting:
            callingState = .RECONNECTING
            break

        default: break
        }
    }






}

