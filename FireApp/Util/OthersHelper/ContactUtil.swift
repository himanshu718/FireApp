//
//  ContactUtil.swift
//  FireApp
//
//  Created by Devlomi on 9/19/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import Contacts
import libPhoneNumber_iOS
import RxFirebaseDatabase
import RxSwift
import FirebaseDatabase
import RxOptional
import RealmSwift

class ContactsUtil {

    //get contacts from phonebook
    public static func getRawContacts() -> [PhoneContact] {
        var foundContacts = [PhoneContact]()
        let contactStore = CNContactStore()

        do {
            let request: CNContactFetchRequest
            request = CNContactFetchRequest(
                keysToFetch: [
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactPhoneNumbersKey as CNKeyDescriptor
                ]
            )
            request.sortOrder = CNContactSortOrder.givenName
            try contactStore.enumerateContacts(with: request) {
                (contact, cursor) -> Void in
                //extract the string number to an array of numbers
                let numbers = contact.phoneNumbers.map({ $0.value.stringValue })
                //ignore contacts with empty numbers
                if !numbers.isEmpty {
                    let name = contact.givenName
                    let phoneContact = PhoneContact(name: name, numbers: numbers)

                    foundContacts.append(phoneContact)
                }
            }
        }
        catch {

        }

        return foundContacts
    }

    public static func extractCountryCodeFromNumber(_ number: String) -> String {
        let phoneUtil = LibPhoneNumberSingleton.instance()

        let nbPhoneNumber = try? phoneUtil.parse(number, defaultRegion: "US")


        let regionCode = phoneUtil.getRegionCode(for: nbPhoneNumber) == nil ? "US" : phoneUtil.getRegionCode(for: nbPhoneNumber)
        return regionCode ?? "US"

    }

    //format number to international number
    //if number is not with international code (+1 for example) we will add it
    //depending on user country ,so if the user number is +1 1234-111-11
    //we will add +1 in this case for all the numbers
    //and if it's contains "-" we will remove them
    public static func formatNumber(countryCode: String, number: String) -> String {
        let phoneUtil = LibPhoneNumberSingleton.instance()


        do {
            let defaultRegion = countryCode.isEmpty ? "US" : countryCode
            let phoneNumber: NBPhoneNumber = try phoneUtil.parse(number, defaultRegion: defaultRegion)
            let formattedString: String = try phoneUtil.format(phoneNumber, numberFormat: .E164)

            return formattedString
        }
        catch {

        }
        return number

    }




    public static func syncContacts(appRealm: Realm) -> Observable<User> {
        let contacts = getRawContacts()
        let contactsObservable = Observable.from(contacts)

        let realmHelper = RealmHelper.getInstance(appRealm)
        let countryCode = UserDefaultsManager.getCountryCode()

        let userObservable = contactsObservable.flatMap { contact -> Observable<(PhoneContact, String)> in
            return Observable.from(contact.numbers).map { (contact, $0) }
        }.flatMap { contact, number -> Observable <(PhoneContact, String)> in
            let formattedNumber = ContactsUtil.formatNumber(countryCode: countryCode, number: number)
            return Observable.from(optional: formattedNumber).map { (contact, $0) }
        }.flatMap { contact, formattedNumber -> Observable<(PhoneContact, DataSnapshot)> in
            if FireManager.isHasDeniedFirebaseStrings(string: formattedNumber){
                return Observable.empty()
            }
            return FireConstants.uidByPhone.child(formattedNumber).rx.observeSingleEvent(.value).map { (contact, $0) }.asObservable()
        }.map { contact, snapshot in
            return (snapshot.value as? String).map { (contact, $0) }
        }.filterNil()
            .flatMap { contact, uid -> Observable<(PhoneContact, DataSnapshot)> in
                return FireConstants.usersRef.child(uid).rx.observeSingleEvent(.value).asObservable().map { (contact, $0) }
            }.map { contact, snapshot -> User in
                let user = snapshot.toUser()
                let userName = contact.name.isEmpty ? user.phone : contact.name
                user.userName = userName
                
                user.isStoredInContacts = true
                return user
            }.do(onNext: { user in
                if let storedUser = realmHelper.getUser(uid: user.uid) {
                    realmHelper.updateUserInfo(newUser: user, storedUser: storedUser, name: user.userName, isStored: user.isStoredInContacts)
                } else {
                    realmHelper.saveObjectToRealm(object: user)
                }
            }, onCompleted: {
                    UserDefaultsManager.setLastContactsSync(date: Date())
                })





        return userObservable



    }

    static func contactExists(phoneNumber: String) -> Observable<Bool> {
        return searchForContactByPhoneNumber(phoneNumber: phoneNumber).map { contact in
            return contact != nil
        }
    }

    static func searchForContactByPhoneNumber(phoneNumber: String) -> Observable<CNContact?> {
        return Observable<CNContact?>.create { (observer) -> Disposable in
            let pred = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phoneNumber))

            let store = CNContactStore()
            do {
                let contacts = try store.unifiedContacts(matching: pred, keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor])

                guard let contact = contacts.first else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return Disposables.create()
                }


                observer.onNext(contact)
                observer.onCompleted()



            } catch let error {
                observer.onNext(nil)//we don't want to show an error since the user may refuse to grant Contacts permissions
                observer.onCompleted()
                return Disposables.create()
            }

            return Disposables.create()
        }
    }
    
    static func deleteDeletedUsers() -> Observable<User> {

         let realmHelper = RealmHelper.getInstance(appRealm)
        return Observable.from(realmHelper.getUsers()).flatMap { user -> Observable<(DataSnapshot,String)> in
            if !user.uid.contains(".") &&
                !user.uid.contains("#") &&
                !user.uid.contains("$") &&
                !user.uid.contains("]") &&
                !user.uid.contains("["){
                let uid = user.uid
                return FireConstants.deletedUsers.child(uid).rx.observeSingleEvent(.value).asObservable().map{($0,uid)}
            }else{
                return FireConstants.deletedUsers.child("aaa").rx.observeSingleEvent(.value).asObservable().map{($0,"aaa")}
            }
         }.flatMap { (snap,uid) -> Observable<User> in
             
             if(snap.exists()){
                 realmHelper.setUserDeleted(userId:uid,b:true)
             }
             return Observable<User>.empty()
         }
     }


}

fileprivate class LibPhoneNumberSingleton {
    private static var phoneUtil: NBPhoneNumberUtil?

    static func instance() -> NBPhoneNumberUtil {
        if phoneUtil == nil {
            phoneUtil = NBPhoneNumberUtil()
        }
        return phoneUtil!
    }
}
