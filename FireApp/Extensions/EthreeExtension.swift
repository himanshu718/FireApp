//
//  EthreeExtension.swift
//  FireApp
//
//  Created by Devlomi on 6/9/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//
import Foundation
import RxSwift
import VirgilE3Kit
import VirgilSDK

extension EThree{
    
    func findUserRx(with:String)  -> Single<Card>{
        return Single<Card>.create { (observer) -> Disposable in
            self.findUser(with: with).start { (card, error) in
                if let error = error{
                    observer(.error(error))
                }else{
                 observer(.success(card!))
                }
            }
            return Disposables.create()
        }
        
    }
    
    func findUsersRx(with:[String],checkResult:Bool)  -> Single<FindUsersResult>{
        return Single<FindUsersResult>.create { (observer) -> Disposable in
            self.findUsers(with: with,checkResult: checkResult).start { (findUsersResult, error) in
                if let error = error{
                    observer(.error(error))
                }else{
                 observer(.success(findUsersResult!))
                }
            }
            
            return Disposables.create()
        }
        
    }
    
    func registerRx() -> Completable {
        return Completable.create { (observer) -> Disposable in
            self.register().start { (void,error) in
                if let error = error{
                    observer(.error(error))
                }
                else{
                observer(.completed)
                }
                
            }
            
            return Disposables.create()

        }
    }
    
    func backupPrivateKeyRx(pwd:String) -> Completable {
        return Completable.create { (observer) -> Disposable in
            self.backupPrivateKey(password: pwd).start { (void,error) in
                if let error = error{
                    observer(.error(error))
                }else{
                    observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    
    func restorePrivateKeyRx(pwd:String) -> Completable {
        return Completable.create { (observer) -> Disposable in
            self.restorePrivateKey(password: pwd).start { (void,error) in
                if let error = error{
                    observer(.error(error))
                }else{
                    observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
}


