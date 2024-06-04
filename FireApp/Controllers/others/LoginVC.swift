//
//  LoginVC.swift
//  FireApp
//
//  Created by Devlomi on 11/26/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseUI
import RxSwift
import Permission


class LoginVC: UIViewController {
    private let disposeBag = DisposeBag()


    override func viewDidLoad() {
        super.viewDidLoad()


        view.backgroundColor = .white

//        let activityIndicator = UIActivityIndicatorView()
//        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(activityIndicator)
//        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        activityIndicator.startAnimating()
    }

    private func login() {
        if #available(iOS 13.0, *) {
            guard let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "authVC") as? AuthVC else {
                print("Failed to instantiate AuthVC from storyboard.")
                return
            }
            present(authVC, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    fileprivate func goToRoot() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

        if UserDefaultsManager.isUserInfoSaved() {
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "RootNavController") as! RootNavController
            self.dismiss(animated: false) {
                self.view.window?.rootViewController = newViewController
            }
        } else {

            let newViewController = storyBoard.instantiateViewController(withIdentifier: "RestoreBackupNavVC") as! UINavigationController

            self.view.window?.rootViewController = newViewController

        }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isLoggedIn{
            goToRoot()
        }else{
            login()
        }
        
        

    }
    
    var isLoggedIn:Bool{
        //if e2e is not enabled, it will be true by default.
        let isE2e = Config.encryptionType == EncryptionType.E2E
        
        let isE2eSaved = isE2e ? UserDefaultsManager.isE2ESaved() : true
        
         return FireManager.isLoggedIn && isE2eSaved
    }
    
}


extension LoginVC: FUIAuthDelegate {

    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error as? NSError {
            login()
        } else {
            //save temp user to fetch the groups if existe and avoid nulls
            if let authResult = authDataResult, let phoneNumber = authResult.user.phoneNumber {
                let realmHelper = RealmHelper.getInstance(appRealm)

                let uid = authResult.user.uid

                let shouldDeleteAfterLogin = realmHelper.shouldDeleteAfterLogin(newUid: uid)
                
                if (shouldDeleteAfterLogin) {
                    realmHelper.deleteRealm()
                }

                
                let currentUid = CurrentUid(uid: uid)
                if shouldDeleteAfterLogin {
                    realmHelper.saveObjectToRealm(object: currentUid)
                } else {
                    realmHelper.saveCurrentUidAndDeleteOldOne(new: currentUid)
                }

             
                FireManager.saveDeviceId(uid: uid).observeOn(MainScheduler.instance).do(onCompleted: {
                    UserDefaultsManager.setDeviceIdSaved(true)
                }).andThen(registerEthreeIfNeeded(uid: uid, shouldDeleteAfterLogin: shouldDeleteAfterLogin)).observeOn(MainScheduler.instance).subscribe { [weak self] in
                    let user = User()
                    user.phone = phoneNumber
                    user.uid = uid


                    realmHelper.saveObjectToRealm(object: user, update: true)

                    if let strongSelf = self {
                        strongSelf.goToRoot()
                    }

                } onError: { (error) in
                    print("error initializeing e3 \(error.localizedDescription)")
                }.disposed(by: disposeBag)
            }

        }
    }

    private func registerEthreeIfNeeded(uid: String, shouldDeleteAfterLogin: Bool) -> Completable {
        if Config.encryptionType == EncryptionType.E2E {
            return EthreeInstance.initialize(identity: uid).flatMapCompletable { ethree in
                
                
                var localPrivateKeyExists = false
                
                if let localPrivateKey = try? ethree.hasLocalPrivateKey(){
                    localPrivateKeyExists = localPrivateKey
                }
                
                if shouldDeleteAfterLogin || localPrivateKeyExists {
                    try? ethree.cleanUp()
                }
                
                return EthreeRegistration.registerEthree(ethree: ethree)
            }.do(onCompleted: {
                UserDefaultsManager.setE2ESaved(true)
            })
        }
        return Completable.empty()
    }
}

