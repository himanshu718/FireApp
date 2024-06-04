//
//  UpdateVC.swift
//  FireApp
//
//  Created by Devlomi on 9/28/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit

class UpdateVC: UIViewController {
    @IBOutlet weak var btnUpdate:UIButton!
    @IBOutlet weak var lblUpdate:UILabel!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        btnUpdate.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
       lblUpdate.numberOfLines = 0
        lblUpdate.lineBreakMode = .byWordWrapping
  
       lblUpdate.frame.size.width = 300
       lblUpdate.sizeToFit()
    }
    
    @objc private func updateTapped(){
        guard let url = URL(string: Config.appLink) else { return }
        
        UIApplication.shared.open(url)
    }


}
