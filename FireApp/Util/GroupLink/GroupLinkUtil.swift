//
//  GroupLinkUtil.swift
//  FireApp
//
//  Created by Devlomi on 10/6/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebase
import FirebaseDatabase

class GroupLinkUtil {
    //this will generate only new key without link
    private static func generateNewKey(groupId: String) -> String {
        return FireConstants.groupsLinks.child(groupId).childByAutoId().key!
    }

    public static func getFinalLink(newKey: String) -> String {
        let host = Config.groupHostLink
        return host + "/" + newKey;
    }

    private static func getCurrentLink(groupId: String) -> Observable<String?> {
        return FireConstants.groupLinkById.child(groupId).rx.observeSingleEvent(.value).asObservable().map {
            if let link = $0.value as? String {
                return link
            }
            return nil
        }
    }

    public static func getLinkAndFetchNewOneIfNotExists(groupId: String) -> Observable<String> {

        return getCurrentLink(groupId: groupId).flatMap { link -> Observable<String> in
            if link == nil {
                //if there is no group link before create new one
                return generateLink(groupId: groupId)
            } else {
                //otherwise get group link
                saveLinkToRealm(groupId: groupId, newKey: link!)
                return Observable.from(optional: link!)
            }
        }
    }

    public static func generateLink(groupId: String) -> Observable<String> {
        let newKey = generateNewKey(groupId: groupId)

        return getCurrentLink(groupId: groupId).flatMap { groupLink -> Observable<String> in
            //if there is no previous link then just save the link
            if groupLink == nil {
                return saveToDatabase(groupId: groupId, newKey: newKey)
            } else {
                //delete old link
                return FireConstants.groupsLinks.child(groupLink!).rx.removeValue().asObservable().flatMap { _ -> Observable<String> in
                    return saveToDatabase(groupId: groupId, newKey: newKey)
                }
            }
        }
    }


    private static func saveToDatabase(groupId: String, newKey: String) -> Observable<String> {
        return FireConstants.groupLinkById.child(groupId).rx.setValue(newKey).asObservable().flatMap { _ in
            return FireConstants.groupsLinks.child(newKey).rx.setValue(groupId)
        }.map { _ -> String in
            saveLinkToRealm(groupId: groupId, newKey: newKey)
            return newKey
        }
    }
    private static func saveLinkToRealm(groupId: String, newKey: String) {
        RealmHelper.getInstance(appRealm).setGroupLink(groupId: groupId, groupLink: newKey)
    }

    private static func isGroupLinkValid(groupLink: String) -> Observable<Bool> {
        return FireConstants.groupsLinks.child(groupLink).rx.observeSingleEvent(.value).asObservable().map { snapshot in
            return snapshot.exists()
        }
    }

    public static func canJoinGroup(groupId: String) -> Observable<Bool> {

        if let groupUser = RealmHelper.getInstance(appRealm).getUser(uid: groupId), let group = groupUser.group {
            if group.isActive {
                return Observable.error(AlreadyInGroupError())
            }
        }

        //if he is not in group,check if he is banned from this group
        return isUserBannedFromGroup(groupId: groupId).flatMap { isUserBanned -> Observable<Bool> in
            //check if the user is banned
            if isUserBanned {
                return Observable.error(UserBannedFromGroupError())
            } else {
                //if all above succeed then the user finaly can join the group
                return Observable.from(optional: true)
            }
        }
    }

    private static func isUserBannedFromGroup(groupId: String) -> Observable<Bool> {
        return FireConstants.deletedGroupsUsers.child(groupId).child(FireManager.getUid()).rx.observeSingleEvent(.value).asObservable().map { snapshot in
            return snapshot.exists()
        }
    }

    public static func checkAndFetchGroupPartialInfo(groupLink: String) -> Observable<(User, Int)> {

        return GroupManager.getGroupIdByGroupLink(groupLink: groupLink).flatMap { groupId in
            return GroupLinkUtil.canJoinGroup(groupId: groupId).map { ($0, groupId) }
        }.flatMap { canJoinGroup, groupId -> Observable<(User, Int)> in

            if canJoinGroup {
                return fetchGroupPartialInfo(groupId: groupId)
            } else {
                return Observable.error(UnknownError())
            }

        }

    }




    private static func getSixUsersOfGroup(snapshot: DataSnapshot) -> Observable<[User]> {

        var observersList = [Observable<User>]()


        var i = 0

        for userSnapshot in snapshot.children.allObjects {
            let userSnap = userSnapshot as! DataSnapshot
            //get only six users
            if i == 6 {
                break
            }
            let uid = userSnap.key
            if let user = RealmHelper.getInstance(appRealm).getUser(uid: uid) {
                observersList.append(Observable.from(optional: user))
            } else {
                observersList.append(FireManager.fetchUserByUid(uid: uid, appRealm: appRealm))
            }
            i += 1
        }

        let observables = Observable.from(observersList).merge().toArray().asObservable()




        return observables


    }


    private static func fetchGroupPartialInfo(groupId: String) -> Observable<(User, Int)> {
        return FireConstants.groupsRef.child(groupId).rx.observeSingleEvent(.value).asObservable().flatMap { snapshot -> Observable<DataSnapshot> in

            if !snapshot.exists() {
                return Observable.error(UnknownError())
            }
            return Observable.from(optional: snapshot)
        }.flatMap { snapshot in

            return getSixUsersOfGroup(snapshot: snapshot.childSnapshot(forPath: "users")).map { (snapshot, $0) }

        }.map { snapshot, sixUsersOfGroup -> (User, Int) in

            let info = snapshot.childSnapshot(forPath: "info")
            let users = snapshot.childSnapshot(forPath: "users")

            //group details
            let groupName = info.childSnapshot(forPath: "name").value as! String
            let photo = info.childSnapshot(forPath: "photo").value as! String
            let thumbImg = info.childSnapshot(forPath: "thumbImg").value as! String
            let createdBy = info.childSnapshot(forPath: "createdBy").value as! String

            let usersInGroupCount = users.childrenCount

            let userGroup = User()
            userGroup.userName = groupName
            userGroup.photo = photo
            userGroup.thumbImg = thumbImg
            let group = Group()
            group.groupId = groupId
            group.createdByNumber = createdBy
            let groupUsers = group.users
            groupUsers.append(objectsIn: sixUsersOfGroup)
            userGroup.group = group

            return (userGroup, Int(usersInGroupCount))
        }
    }

}
