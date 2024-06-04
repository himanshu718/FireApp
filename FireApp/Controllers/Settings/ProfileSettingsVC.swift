//
//  ProfileVC.swift
//  FireApp
//
//  Created by Devlomi on 11/16/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import ALCameraViewController

class ProfileSettingsVC: BaseVC {

    var user: User!
    
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var btnPickImage: UIButton!
    
   
    @IBOutlet weak var vendorStatusLbl: UILabel!
    
    @IBOutlet weak var vendorPhoneNumberLbl: UILabel!
    
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var phoneNumberLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var extraPhoneNumberLbl: UILabel!
    
    @IBOutlet weak var btnEditUsername: UIButton!

    @IBOutlet weak var VenderCardView: UIView!
    @IBOutlet weak var OperatorCardView: UIView!
    
//    @IBOutlet weak var operatornumberLbl: UILabel!
    @IBOutlet weak var operatorNameLbl: UILabel!
    @IBOutlet weak var vehicletypeLbl: UILabel!
    @IBOutlet weak var operatorAddressLbl: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Profile"
        self.navigationController?.navigationBar.topItem?.title = ""
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
        print(user.statelist)
        
       
        
        

        btnEditUsername.addTarget(self, action: #selector(btnEditUsernameTapped), for: .touchUpInside)
        btnPickImage.addTarget(self, action: #selector(btnPickImageTapped), for: .touchUpInside)
        statusLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(statusLblTapped)))
        vendorStatusLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(statusLblTapped)))
        setUI()
    }
    
    @IBAction func btnLogout(_ sender: UIButton) {
        FireManager.logout()
        AppDelegate.shared.goToInitialVC()
    }
    
    //set user's info
    private func setUI() {
        vendorStatusLbl.text = user.status
        vendorPhoneNumberLbl.text = user.phone
        userNameLbl.text = user.userName
        statusLbl.text = user.status
        phoneNumberLbl.text = user.phone
        emailLbl.text = user.email
        addressLbl.text = user.address
//        operatornumberLbl.text = user.extra_phone_number
        extraPhoneNumberLbl.text = user.extra_phone_number
        
        operatorNameLbl.text = user.fullName
        vehicletypeLbl.text = user.vehicleType
        operatorAddressLbl.text = user.homeAddress

        userImg.image = UIImage(contentsOfFile: user.userLocalPhoto)
        
        if user.userType == "Vendor" {
            OperatorCardView.isHidden = true
        } else {
            VenderCardView.isHidden = true
        }
    }

    //change status
    @objc private func statusLblTapped() {
        let alert = UIAlertController(title: Strings.enter_your_status, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = Strings.status
            textField.text = self.user.status
        }

        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: { (_) in
            if let newStatus = alert.textFields?[0].text, newStatus.isNotEmpty {
                self.showLoadingViewAlert()

                FireManager.changeMyStatus(status: newStatus,appRealm: appRealm).subscribe(onCompleted: {
                    self.hideLoadingViewAlert()
                    self.setUI()
                }) { (error) in
                    self.hideLoadingViewAlert()
                }.disposed(by: self.disposeBag)
            }
        }))

        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))

        self.present(alert, animated: true)

    }

    //change user's image
    @objc private func btnPickImageTapped() {

        let cameraViewController = CropImageRequest.getRequest { (image, asset) in
            if let image = image {
                self.showLoadingViewAlert()
                FireManager.changeMyPhoto(image: image,appRealm: appRealm).subscribe(onCompleted: {
                    self.hideLoadingViewAlert()
                    self.setUI()
                }) { (error) in
                    self.hideLoadingViewAlert()
                }.disposed(by: self.disposeBag)
            }
            self.dismiss(animated: true, completion: nil)
        }
      
        present(cameraViewController, animated: true, completion: nil)
    }

    //change user's name
    @objc private func btnEditUsernameTapped() {
        let alert = UIAlertController(title: Strings.enter_your_name, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = Strings.name
            textField.text = self.user.userName
        }

        alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: { (_) in
            if let newUserName = alert.textFields?[0].text, newUserName.isNotEmpty {
                self.showLoadingViewAlert()

                FireManager.changeUserName(userName: newUserName,appRealm: appRealm).subscribe(onCompleted: {
                    self.hideLoadingViewAlert()
                    self.setUI()
                }) { (error) in
                    self.hideLoadingViewAlert()
                }.disposed(by: self.disposeBag)
            }
        }))

        alert.addAction(UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
}
