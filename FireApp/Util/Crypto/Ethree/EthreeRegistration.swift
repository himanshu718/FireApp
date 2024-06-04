//
//  EthreeRegistration.swift
//  FireApp
//
//  Created by Devlomi on 6/9/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import RxSwift
import VirgilE3Kit
import FirebaseDatabase

class EthreeRegistration {
    static func registerEthree(ethree: EThree) -> Completable {
        return ethree.registerRx().andThen(backupPrivateKey(eThree: ethree)).catchError { (error) -> PrimitiveSequence<CompletableTrait, Never> in
            if let ethreeError = error as? EThreeError, ethreeError == EThreeError.userIsAlreadyRegistered {
                return restorePrivateKey(eThree: ethree)
            }
            return Completable.error(error)
        }
    }

    private static func backupPrivateKey(eThree: EThree) -> Completable {
        if let password = try? PKPwEncryptUtil.generatePKPwd() {
            return eThree.backupPrivateKeyRx(pwd: password).andThen(saveKeyPwd(pwd: password))

        } else {
            return Completable.error(NSError(domain: "error generating pk pwd", code: -1, userInfo: nil))
        }

    }





    private static func restorePrivateKey(eThree: EThree) -> Completable {
        return getKeyPwdToDb().flatMapCompletable { password in
            return eThree.restorePrivateKeyRx(pwd: password)
        }

    }

    private static func saveKeyPwd(pwd: String) -> Completable {
        return FireConstants.pkPwd.child(FireManager.getUid()).rx.setValue(pwd).asCompletable()
    }

    private static func getKeyPwdToDb() -> Single<String> {
        return FireConstants.pkPwd.child(FireManager.getUid()).rx.observeSingleEvent(.value).flatMap { (snapshot) -> Single<String> in
            if let keyPwd = snapshot.value as? String {

                return Single.just(keyPwd)
            } else {
                return Single.error(NSError(domain: "Could not find keyPwd", code: -1, userInfo: nil))
            }
        }
    }

}
