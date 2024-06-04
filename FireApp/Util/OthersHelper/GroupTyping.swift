//
//  GroupTyping.swift
//  FireApp
//
//  Created by Devlomi on 10/24/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift
import RealmSwift

class GroupTyping {
    private var users: List<User>!
    private var typingDict: [String: (TypingState, Int)]!

    private var groupId = ""

    private var delegate: GroupTypingDelegate?
    private var disposeBag: DisposeBag!


    init(groupId: String, users: List<User>, disposeBag: DisposeBag, delegate: GroupTypingDelegate) {

        self.users = users
        self.groupId = groupId
        self.delegate = delegate

        typingDict = [String: (TypingState, Int)]()

        FireConstants.groupTypingStat.child(groupId).rx.observeEvent(.childAdded).subscribe { (snapshot) in
            self.onChange(dataSnapshot: snapshot.element, groupId: groupId)
        }.disposed(by: disposeBag)

        FireConstants.groupTypingStat.child(groupId).rx.observeEvent(.childChanged).subscribe { (snapshot) in
            self.onChange(dataSnapshot: snapshot.element, groupId: groupId)
        }.disposed(by: disposeBag)





    }

    private func onChange(dataSnapshot: DataSnapshot?, groupId: String) {
        guard let dataSnapshot = dataSnapshot else {
            return
        }

        if (!dataSnapshot.exists()) {
            return
        }
        if (dataSnapshot.key == FireManager.getUid()) {
            return
        }

        guard let intStat = dataSnapshot.value as? Int else{
            return
        }
        
        let stat = TypingState(rawValue: intStat)!
        let uid = dataSnapshot.key

        if (uid == FireManager.getUid()) {
            return
        }
        //if user stops typing,remove him from map
        // then check if there is another user is typing ,if so notify the callback
        //and if there is no other user is typing notify callback that there are no users  typing

        //and if a user is typing ,add him to map and notify callback

        if (stat == .NOT_TYPING) {
            typingDict.removeValue(forKey: uid)
            if (typingDict.isEmpty) {
                delegate?.onAllNotTyping(groupId: groupId);
            } else {
                //get last user typing state
                if let lastUserTyping = getLastUserTyping(), let tuple = typingDict[lastUserTyping.uid] {
                    let state = tuple.0

                    //set last user typing state
                    delegate?.onTyping(state: state, groupId: groupId, user: lastUserTyping)
                }

            }

        } else {
            typingDict[uid] = (stat, getIndex())

            delegate?.onTyping(state: stat, groupId: groupId, user: getLastUserTyping())
        }

    }
    private func getLastUserTyping() -> User? {
        var index = 0;
        var user: User?
        typingDict.keys.forEach { (key) in
            let tuple = typingDict[key]
            let typingStateIndex = tuple!.1

            if (typingStateIndex > index || typingDict.count == 1) {
                index = typingStateIndex
                user = users.filter { $0.uid == key }.first
            }
        }

        return user;
    }

    private func getIndex() -> Int {
        var index = 0

        if (typingDict.isEmpty) {
            return index
        }

        typingDict.keys.forEach { (key) in
            let typingStateIndex = typingDict[key]!.1
            if typingStateIndex > index {
                index = typingStateIndex
            }
        }


        return index + 1;
    }

}
protocol GroupTypingDelegate {
    func onTyping(state: TypingState, groupId: String, user: User?)
    func onAllNotTyping(groupId: String)
}
