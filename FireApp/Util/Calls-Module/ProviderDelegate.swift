//
//  ProviderDelegate.swift
//  Hotline
//
//  Created by Besher on 2018-05-28.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import AVFoundation
import CallKit
import RxSwift
import AgoraRtcKit


private let sharedProviderDelegate = ProviderDelegate()
private let agoraKit = AppDelegate.shared.agoraKit

class ProviderDelegate: NSObject {
    private let disposeBag = DisposeBag()

     

    
    class var sharedInstance: ProviderDelegate {
        return sharedProviderDelegate
    }

    fileprivate let provider: CXProvider?
    fileprivate let callController: CXCallController

    private var audioSession: AVAudioSession?






    override init() {
        provider = CXProvider(configuration: type(of: self).providerConfiguration)

        callController = CXCallController.init()

        super.init()

        provider?.setDelegate(self, queue: nil)

    }

    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: Config.appName)
      
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.includesCallsInRecents = true
        providerConfiguration.supportedHandleTypes = [.phoneNumber, .generic]
        return providerConfiguration
    }


    var headers: [AnyHashable: Any]?

    func reportIncomingCall(_ call: FireCall) {

        let uuid = UUID(uuidString: call.callUUID)!


        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: call)



        let update = CXCallUpdate()


        if call.phoneNumber.isNotEmpty {
            update.remoteHandle = CXHandle(type: .phoneNumber, value: call.phoneNumber)
        } else {
            update.remoteHandle = CXHandle(type: .generic, value: call.user!.userName)
        }

        update.supportsGrouping = false
        update.supportsUngrouping = false

        update.supportsHolding = false


        update.hasVideo = call.callType.isVideo

        provider?.reportNewIncomingCall(with: uuid, update: update) { error in

            if error == nil {

//                call.delegate = self
//                CallManager.sharedInstance.addIncoming(call: call)
            }
        }
    }

    func reportMissedCall(uuid: UUID, date: Date, reason: CXCallEndedReason) {
        provider?.reportCall(with: uuid, endedAt: date, reason: reason)
    }


    var objPlayer: AVAudioPlayer?

    func playAudioFile() {


        guard let url = Bundle.main.url(forResource: "progress_tone", withExtension: "wav") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            // For iOS 11
            objPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            objPlayer?.numberOfLoops = -1


            guard let aPlayer = objPlayer else { return }
            aPlayer.play()

        } catch let error {
        }


    }


    func endCall(fireCall: FireCall, reason: CallEndedReason, duration: Int) {

        end(fireCall: fireCall, reason: reason)



        RealmHelper.getInstance(appRealm).updateCallInfoOnCallEnded(callId: fireCall.callId, duration: duration)
        objPlayer?.stop()



    }

}

extension ProviderDelegate: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        AppDelegate.shared.isInCall = false
    }



    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let fireCall = RealmHelper.getInstance(appRealm).getFireCallByUUID(callUUID: action.callUUID.uuidString) else {
            action.fail()
            return
        }

        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat, options: [.duckOthers, .allowBluetoothA2DP, .allowBluetooth])


        action.fulfill()
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: "CallingVC") as! CallingVC


        
       



        vc.initialize(fireCall: fireCall)
        vc.modalPresentationStyle = .fullScreen
        AppDelegate.shared.window?.rootViewController?.present(vc, animated: true, completion: nil)
        AppDelegate.shared.isInCall = true

        RealmHelper.getInstance().setCallDirection(callId: fireCall.callId, callDirection: .ANSWERED)
    }



    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let fireCall = RealmHelper.getInstance(appRealm).getFireCallByUUID(callUUID: action.callUUID.uuidString) else {
            action.fail()
            return
        }





        action.fulfill()

        AppDelegate.shared.isInCall = false
        FireCallsManager().setCallEnded(callId: fireCall.callId, otherUid: fireCall.user!.uid, isIncoming: fireCall.callDirection == .INCOMING).subscribe().disposed(by: disposeBag)

        if fireCall.callDirection != .ANSWERED {
            RealmHelper.getInstance().setCallDirection(callId: fireCall.callId, callDirection: .MISSED)
        }

//        CallManager.sharedInstance.remove(call: call)
    }

    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {

        return false
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        self.audioSession = audioSession

        try? audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.voiceChat, options: [.duckOthers, .allowBluetoothA2DP, .allowBluetooth])
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {

    }



    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if var topController = AppDelegate.shared.window?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }


            // When entering the application via the App button on the CallKit lockscreen,
            // and unlocking the device by PIN code/Touch ID, applicationWillEnterForeground:
            // will be invoked twice, and "top" will be CallViewController already after
            // the first invocation.
            if let callingVC = topController as? CallingVC {

                callingVC.isMuted = !callingVC.isMuted
            }
        }

        action.fulfill()
    }



    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    func reportOutgoingStarted(uuid: UUID) {

        provider?.reportOutgoingCall(with: uuid, startedConnectingAt: nil)
    }

    func reportOutoingConnected(uuid: UUID) {
        provider?.reportOutgoingCall(with: uuid, connectedAt: nil)
    }

}


extension ProviderDelegate {


    func end(fireCall: FireCall, reason: CallEndedReason) {
        provider?.reportCall(with: UUID(uuidString: fireCall.callUUID)!, endedAt: Date(), reason: getCallEndedReason(reason))
        AppDelegate.shared.isInCall = false

    }

    private func requestTransaction(_ transaction: CXTransaction) {

        callController.request(transaction, completion: { (error: Error?) in

            if error != nil {
                
            }
        })



    }





    func setMute(mute: Bool) {

//        let setMuteCallAction = CXSetMutedCallAction(call: call.uuid, muted: mute)
//        let transaction = CXTransaction()
//        transaction.addAction(setMuteCallAction)
//
//        requestTransaction(transaction)

        agoraKit?.muteLocalAudioStream(mute)


    }

    func setSpeaker(loud: Bool) {



        agoraKit?.setEnableSpeakerphone(loud)

    }


    private func getCallEndedReason(_ cause: CallEndedReason) -> CXCallEndedReason {
        switch cause {
        case .ERROR:
            return .failed
        case .REMOTE_REJECTED:
            return .remoteEnded
        case .REMOTE_HUNG_UP:
            return .remoteEnded

        case .NO_ANSWER:
            return .unanswered

        default: return .unanswered
        }

    }
}
