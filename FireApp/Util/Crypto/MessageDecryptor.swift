//
//  MessageDecryptor.swift
//  FireApp
//
//  Created by Devlomi on 6/11/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift


struct MessageDecryptor {
    let decryptionHelper: DecryptionHelper

    func decryptMessage(message: Message) -> Single<Message> {
        var singles = [Single<Any>]()

        singles.append(decryptContent(message: message).map {
                message.content = $0
                return $0
            })

        singles.append(decryptPartialText(message: message).map {
                message.partialText = $0
                return $0
            })

        singles.append(decryptThumb(message: message).map {
                message.thumb = $0
                return $0
            })

        singles.append(decryptContact(message: message).map {
                message.contact = $0
                return $0
            })

        singles.append(decryptLocation(message: message).map {
                message.location = $0
                return $0
            })
        
        return Single.zip(singles).map { _ in
            return message
        }

    }


    private func decryptContent(message: Message) -> Single<String> {
        if message.content.isEmpty {
            return Single.just(message.content)
        }
        let fromId = message.fromId
        return decryptionHelper.decrypt(fromId: fromId, message: message.content, encryptionType: message.encryptionType)
    }


    private func decryptPartialText(message: Message) -> Single<String> {
        if (message.partialText.isEmpty) {
            return Single.just(message.partialText)
        }


        let fromId = message.fromId


        return decryptionHelper.decrypt(fromId: fromId, message: message.partialText, encryptionType: message.encryptionType)

    }



    private func decryptContact(message: Message) -> Single<RealmContact?> {
        guard let contact = message.contact else {
            return Single.just(message.contact)
        }


        let fromId = message.fromId




        var singles = [Single<String>]()

        if contact.name.isNotEmpty {

            singles.append(decryptionHelper.decrypt(fromId: fromId, message: contact.name, encryptionType: message.encryptionType).map {
                    contact.name = $0
                    return $0
                })

        }


        if contact.jsonString.isNotEmpty {
            singles.append(
                decryptionHelper.decrypt(fromId: fromId, message: contact.jsonString, encryptionType: message.encryptionType).map { decryptedJsonString -> String in

                    let numbers = ContactMapper.mapStringToNumbers(numbersString: decryptedJsonString)
                    let newList = List<PhoneNumber>()
                    newList.append(objectsIn: numbers)
                    contact.realmList = newList
                    return decryptedJsonString
                }
            )
        }

        return Single.zip(singles).map { _ in
            return contact
        }
    }

    private func decryptThumb(message: Message) -> Single<String> {
        if message.thumb.isEmpty {
            return Single.just(message.thumb)
        }


        let fromId = message.fromId

        return decryptionHelper.decrypt(fromId: fromId, message: message.thumb, encryptionType: message.encryptionType)
    }


    private func decryptLocation(message: Message) -> Single<RealmLocation?> {
        guard let location = message.location else {
            return Single.just(message.location)
        }


        let fromId = message.fromId



        var singles = [Single<String>]()

        if location.name.isNotEmpty {

            singles.append(
                decryptionHelper.decrypt(fromId: fromId, message: location.name, encryptionType: message.encryptionType).map {
                    location.name = $0
                    return $0
                }
            )
        }

        if location.address.isNotEmpty {
            singles.append(
                decryptionHelper.decrypt(fromId: fromId, message: location.address, encryptionType: message.encryptionType).map {
                    location.address = $0
                    return $0
                }
            )
        }

        if location.latStr.isNotEmpty {
            singles.append(
                decryptionHelper.decrypt(fromId: fromId, message: location.latStr, encryptionType: message.encryptionType).map {
                    location.latStr = $0
                    if let lat = Double($0) {
                        location.lat = lat
                    }
                    return $0
                }
            )
        }
        if location.lngStr.isNotEmpty {
            singles.append(
                decryptionHelper.decrypt(fromId: fromId, message: location.lngStr, encryptionType: message.encryptionType).map {
                    location.lngStr = $0
                    if let lng = Double($0) {
                        location.lng = lng
                    }
                    return $0
                }
            )
        }

        return Single.zip(singles).map { _ in
            return location
        }


    }


}
