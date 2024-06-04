//
//  ShareGroupLinkVC.swift
//  FireApp
//
//  Created by Devlomi on 10/7/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift

class ShareGroupLinkVC: BaseVC {
    @IBOutlet weak var groupImg: EnhancedCircleImageView!

    @IBOutlet weak var groupName: UILabel!

    @IBOutlet weak var groupLink: UITextView!

    @IBOutlet weak var progressView: UIActivityIndicatorView!

    @IBOutlet weak var groupDisclaimer: UITextView!

    @IBOutlet weak var btnShareLink: UIButton!


    @IBOutlet weak var btnCopyLink: UIButton!

    @IBOutlet weak var btnRevokeLink: UIButton!

    private var groupId: String = ""
    private var groupUser: User?
    private var group: Group?
    override func viewDidLoad() {
        super.viewDidLoad()

        if let groupUser = groupUser, let group = group {


            groupName.text = groupUser.userName
            groupImg.image = groupUser.thumbImg.toUIImage()

            //if there is no group link exists in Realm disable clicks
            //then start to fetch the link, if the link was not created before,
            //create a new one and save it to realm
            disableClicks()
            if group.currentGroupLink != "" {
                enableClicks()
                setLinkText(group.currentGroupLink)
            } else {
                hideOrShowProgress(true)
                groupLink.text = Strings.no_link_generated
                GroupLinkUtil.getLinkAndFetchNewOneIfNotExists(groupId: groupId).subscribe(onNext: { (link) in
                    self.enableClicks()
                    self.setLinkText(link)
                    self.hideOrShowProgress(false)
                }, onError: { (_) in
                        self.disableClicks()
                    }).disposed(by: disposeBag)
            }
        }

        btnShareLink.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        btnCopyLink.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        btnRevokeLink.addTarget(self, action: #selector(revokeTapped), for: .touchUpInside)

    }

    @objc private func shareTapped() {


        let activityViewController = UIActivityViewController(activityItems: [groupLink.text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash


        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)


    }

    @objc private func copyTapped() {
        if let group = group {
            UIPasteboard.general.string = groupLink.text
            showAlert(type:.success,message: Strings.copied_to_clipboard)
        }
    }

    @objc private func revokeTapped() {
        hideOrShowProgress(true)
        GroupLinkUtil.generateLink(groupId: groupId).subscribe(onNext: { (groupLink) in
            self.setLinkText(groupLink)
            self.hideOrShowProgress(false)
        }, onError: { (error) in
            self.showAlert(type:.error,message: Strings.error)
            }).disposed(by: disposeBag)
    }


    private func hideOrShowProgress(_ showProgress: Bool) {
        progressView.isHidden = !showProgress
        groupLink.isHidden = showProgress
    }

    private func disableClicks() {
        btnShareLink.isEnabled = false
        btnCopyLink.isEnabled = false
        btnRevokeLink.isEnabled = false
    }

    private func enableClicks() {
        btnShareLink.isEnabled = true
        btnCopyLink.isEnabled = true
        btnRevokeLink.isEnabled = true
    }
    private func setLinkText(_ text: String) {
        groupLink.text = GroupLinkUtil.getFinalLink(newKey: text)
    }

    func initialize(groupId: String) {
        self.groupId = groupId
        groupUser = RealmHelper.getInstance(appRealm).getUser(uid: groupId)
        group = groupUser?.group
    }
}
