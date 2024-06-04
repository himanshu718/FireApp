//
//  EthreeInstance.swift
//  FireApp
//
//  Created by Devlomi on 6/9/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import Foundation
import VirgilE3Kit
import RxSwift
import FirebaseFunctions
import VirgilSDK


class EthreeInstance{
    private static var ethree:EThree?=nil
    
    static func initialize(identity:String = FireManager.getUid()) -> Single<EThree>{
        
     
        
        return Single<EThree>.create { (observer) -> Disposable in
            if let ethree = ethree{
                observer(.success(ethree))
                return Disposables.create()
            }
            let tokenCallback: EThree.RenewJwtCallback = { completion in
                Functions.functions().httpsCallable("getVirgilJwt").rx.call().map { (result:HTTPSCallableResult) -> String in
                    let data = result.data as! [String:Any]
                    let token = data["token"] as! String
                    return token
                }.asSingle().subscribe { (token) in
                    completion(token, nil)

                } onError: { (error) in
                    completion(nil, error)
                    observer(.error(error))
                }

            }
            
            do{
                let keychainStorageParams = try KeychainStorageParams.makeKeychainStorageParams(appName: Config.appName)
                
                ethree = try EThree(identity: identity, tokenCallback: tokenCallback,storageParams: keychainStorageParams)
    
                observer(.success(ethree!))
                        
            }catch{
                observer(.error(error))
            }
                
    

            return Disposables.create()
        }
    }
}
