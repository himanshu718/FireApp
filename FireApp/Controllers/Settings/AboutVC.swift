//
//  AboutVC.swift
//  FireApp
//
//  Created by Devlomi on 11/16/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class AboutVC: BaseVC {

    @IBOutlet weak var appDesc: UITextView!
    @IBOutlet weak var btnWebsite: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    @IBOutlet weak var btnEmail: UIButton!
    @IBOutlet weak var appNameLbl: UILabel!

    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var btnInstagram: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "About us"
        self.navigationController?.navigationBar.topItem?.title = ""

        appNameLbl.text = Config.appName

        btnFacebook.addTarget(self, action: #selector(facebookTapped), for: .touchUpInside)
        btnInstagram.addTarget(self, action: #selector(instagramTapped), for: .touchUpInside)
        btnWebsite.addTarget(self, action: #selector(websiteTapped), for: .touchUpInside)
        btnTwitter.addTarget(self, action: #selector(twitterTapped), for: .touchUpInside)
        btnEmail.addTarget(self, action: #selector(emailTapped), for: .touchUpInside)
        appDesc.text = "GOFERNETS LOGISTICS AND SERVICES is a registered Freight Packaging & Logistics Services Company. We are in the business of connecting all dispatch firms, independent dispatch riders and vendors throughout the entirety of the world."



    }
    
    @objc private func facebookTapped() {
        if let url = URL(string: Config.facebook) {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func instagramTapped() {
        if let url = URL(string: Config.instagram) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func websiteTapped() {
        if let url = URL(string: Config.website) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func twitterTapped() {
        if let url = URL(string: Config.twitter) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func emailTapped() {
        if let url = URL(string: "mailto:\(Config.email)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

}
