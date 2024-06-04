//
//  SaveE2EVC.swift
//  FireApp
//
//  Created by Devlomi on 6/10/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
import RxSwift

class SaveE2EVC: UIViewController {
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        EthreeInstance.initialize().flatMapCompletable{ethree in
            var localPrivateKeyExists = false
            
            if let localPrivateKey = try? ethree.hasLocalPrivateKey(){
                localPrivateKeyExists = localPrivateKey
            }
            
            if localPrivateKeyExists {
                try? ethree.cleanUp()
            }
            
            return EthreeRegistration.registerEthree(ethree: ethree).observeOn(MainScheduler.instance)
        }.subscribe(onCompleted:{
            DispatchQueue.main.async {
                UserDefaultsManager.setE2ESaved(true)
                AppDelegate.shared.goToInitialVC()
            }
        },onError: { (error) in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: Strings.error, message: Strings.unknown_error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }).disposed(by: disposeBag)
    }
}
