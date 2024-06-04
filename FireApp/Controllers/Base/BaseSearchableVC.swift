//
//  BaseSearchableVC.swift
//  FireApp
//
//  Created by Devlomi on 1/2/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import GoogleMobileAds

class BaseSearchableVC: BaseVC, Searchable {
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerView: GADBannerView!

    private var initialTableViewBottomConstraint: CGFloat = 0

    var tableViewPadding: CGFloat = 20

    var enableAds = false
    var adUnitAd = "ca-app-pub-3940256099942544/2934735716"

    fileprivate func loadAd() {
        bannerView.adUnitID = adUnitAd
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForKeyboard = true

        if enableAds {
            loadAd()
        } else {
            if bannerView != nil {
                bannerView.translatesAutoresizingMaskIntoConstraints = false
                bannerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            }
        }
    }

    override func keyboardWillShow(keyboardFrame: CGRect?) {
        if let frame = keyboardFrame {
            let percent:CGFloat = enableAds ? 1.6 : 1.3
            tableViewBottomConstraint.constant = (frame.height / percent)
        }
    }

    override func keyBoardWillHide() {
        tableViewBottomConstraint.constant = initialTableViewBottomConstraint

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if initialTableViewBottomConstraint == 0 {
            initialTableViewBottomConstraint = tableViewBottomConstraint.constant
        }
    }

}
