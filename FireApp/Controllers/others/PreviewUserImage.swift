//
//  PreviewUserImage.swift
//  FireApp
//
//  Created by Devlomi on 10/10/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import Hero

class PreviewUserImage: BaseVC {

    @IBOutlet weak var userImgView: UIImageView!
    private var panGR = UIPanGestureRecognizer()

    private var user: User!


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        panGR.addTarget(self, action: #selector(pan))
        panGR.delegate = self
        
        userImgView.isUserInteractionEnabled = true
        userImgView.addGestureRecognizer(panGR)
        
        self.hero.isEnabled = true
        
        userImgView.hero.id = "user_image_id"
        
        userImgView.hero.modifiers = [.position(CGPoint(x: view.bounds.width / 2, y: view.bounds.height + view.bounds.width / 2)), .scale(0.6), .fade]
        userImgView.isOpaque = true


        if user.userLocalPhoto != "" {
            userImgView.image = UIImage(contentsOfFile: user.userLocalPhoto)
        } else {
            userImgView.image = user.thumbImg.toUIImage()
        }

        
        



        FireManager.checkAndDownloadUserPhoto(user: user,appRealm: appRealm).subscribe(onSuccess: { (arg0) in
            let userPhotoPath = arg0.1
            self.userImgView.image = UIImage(contentsOfFile: userPhotoPath)
        }, onError: nil).disposed(by: disposeBag)

    }

    public func initialize(user: User) {
        self.user = user
    }
    
    @objc func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / view!.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
                let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
                Hero.shared.apply(modifiers: [.position(currentPos)], to: userImgView)

        default:
            if progress + panGR.velocity(in: nil).y / view!.bounds.height > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }


}

extension PreviewUserImage: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let v = panGR.velocity(in: nil)
        return v.y > abs(v.x)
    }
    
}

