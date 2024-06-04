//
//  FireCallsManager.swift
//  FireApp
//
//  Created by Devlomi on 9/19/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import RealmSwift
import RxSwift
import FirebaseDatabase
import RxFirebaseDatabase

class FireCallsManager {
    static let CALL_TIEMOUT_SECONDS = 40

    func saveOutgoingCallOnFirebase(fireCall: FireCall, otherUid: String) -> Single<DatabaseReference> {
        var dict = [String: Any]()

        dict["timestamp"] = ServerValue.timestamp()
        dict["callType"] = fireCall.callType.rawValue
        dict["callId"] = fireCall.callId
        dict["callerId"] = FireManager.getUid()
        dict["phoneNumber"] = fireCall.phoneNumber
        dict["toId"] = fireCall.user!.uid

        dict["channel"] = fireCall.channel
        return FireConstants.newCallsRef.child(otherUid).child(FireManager.getUid()).child(fireCall.callId).rx.setValue(dict)
    }

    func saveOutgoingGroupCallOnFirebase(fireCall: FireCall, groupId: String) -> Single<DatabaseReference> {
        var dict = [String: Any]()

        dict["timestamp"] = ServerValue.timestamp()
        dict["callType"] = fireCall.callType.rawValue
        dict["callId"] = fireCall.callId
        dict["groupId"] = groupId
        dict["callerId"] = FireManager.getUid()
        dict["channel"] = fireCall.channel

        return FireConstants.groupCallsRef.child(groupId).child(fireCall.callId).rx.setValue(dict)
    }


//this will reject/decline/hangup a call
    func setCallEnded(callId: String, otherUid: String, isIncoming: Bool) -> Single<DatabaseReference> {
        if (isIncoming) {
            return FireConstants.newCallsRef.child(FireManager.getUid()).child(otherUid).child(callId).child("ended_incoming").rx.setValue(FireManager.getUid())
        } else {
            return FireConstants.newCallsRef.child(otherUid).child(FireManager.getUid()).child(callId).child("ended_outgoing").rx.setValue(FireManager.getUid())
        }
    }

    func listenForEndingCall(callId: String, otherUid: String, isIncoming: Bool) -> Observable<DataSnapshot> {
        if (isIncoming) {
            return FireConstants.newCallsRef.child(FireManager.getUid()).child(otherUid).child(callId).child("ended_outgoing").rx.observeEvent(.value)
        } else {
            return FireConstants.newCallsRef.child(otherUid).child(FireManager.getUid()).child(callId).child("ended_incoming").rx.observeEvent(.value)
        }
    }

}
