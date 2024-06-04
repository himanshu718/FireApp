//
//  SetupUserVC.swift
//  FireApp
//
//  Created by Devlomi on 11/28/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseDatabase
import FirebaseStorage
import Kingfisher
import FirebaseMessaging
import Permission
import FirebaseFirestore
import DropDown

class SetupUserVC: BaseVC,  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker = UIImagePickerController()
    var pickedImage: UIImage?
    var currentUserPhotoUrl = ""
    var currentUserPhotoThumb = ""
    var fetchUserImageDisposable: Disposable!
    var isGovIdVerified: Bool = false
    var isBillVerified: Bool = false
    var isCeoImageVerified: Bool = false
    var isDocumnetIdVerified: Bool = false


    
    lazy var doneButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .init(hexString: "FE5723")
        button.tintColor = .white
        button.setImage(#imageLiteral(resourceName: "check"), for: .normal )
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()
    
    let dropDown = DropDown()
//    var ceoImageData: Data? = nil
//    var businessImageData: Data? = nil
//    var utilityImageData: Data? = nil
    
    var netsAvailable = 0
    
    //MARK: - Outlets
    
    @IBOutlet weak var viewUserIMG: UIView!
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var txtYourName: UITextField!
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var txtPhoneNumber: UITextField!
    
    @IBOutlet weak var txtBusinessName: UITextField!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var cvVehicleType: UICollectionView!
    @IBOutlet weak var segmentVendor: UISegmentedControl!
    @IBOutlet weak var operatorView: UIView!
    
    @IBOutlet weak var venderView: UIView!
    @IBOutlet weak var txtVenderEmail: UITextField!
    @IBOutlet weak var txtVenderAddress: UITextField!
    @IBOutlet weak var txtVenderExtraPhoneNumber: UITextField!
//    @IBOutlet weak var segmentVendorGender: UISegmentedControl!
    
    @IBOutlet weak var segmentBusiness: UISegmentedControl!
    
    @IBOutlet weak var lblUploadCEOImg: UILabel!
    @IBOutlet weak var lblUploadIDImg: UILabel!
    
    @IBOutlet weak var segmentGender: UISegmentedControl!
    
    @IBOutlet weak var txtFullName: UITextField!
    
    @IBOutlet weak var txtHomeAddress: UITextField!
    
    @IBOutlet weak var txtYourBusiness: UITextField!
    
    @IBOutlet weak var txtInstagram: UITextField!
    @IBOutlet weak var txtFacebook: UITextField!
    @IBOutlet weak var txtTwitter: UITextField!
    
    @IBOutlet weak var cvStates: UICollectionView!
    
    @IBOutlet weak var segmentHouseOffice: UISegmentedControl!
    
    @IBOutlet weak var segmentPerishableFood: UISegmentedControl!
    @IBOutlet weak var segmentPickupDelivery: UISegmentedControl!
    
    @IBOutlet weak var lblUtilityBillImg: UILabel!
    
    @IBOutlet weak var viewIndependetItems: UIView!
    @IBOutlet weak var viewDispatchItems: UIView!
    
    @IBOutlet weak var lblStateTopAnchgor: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    @IBOutlet weak var btnCeoImage: UIButton!
    
    @IBOutlet weak var btnIdImage: UIButton!
    
    
    @IBOutlet weak var lblCeoTitle: UILabel!
    
    @IBOutlet weak var lblIdTitle: UILabel!
    
    @IBOutlet weak var emailTextOperator: UITextField!
    
    //MARK: - View cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        txtVenderEmail.text = FireManager.email
        txtVenderEmail.isUserInteractionEnabled = false
        emailTextOperator.text = FireManager.email
        emailTextOperator.isUserInteractionEnabled = false
        

        imagePicker.delegate = self
        operatorView.isHidden = true
        scrollView.isScrollEnabled = false
        
        segmentVendor.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentVendor.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        
//        segmentVendorGender.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
//        segmentVendorGender.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        
        segmentGender.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentGender.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        
        segmentHouseOffice.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentHouseOffice.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        
        segmentPerishableFood.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentPerishableFood.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        
        segmentPickupDelivery.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentPickupDelivery.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        
        viewUserIMG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userImgTapped)))
        
        setupCollectionView()
        
        //fetch current user image
        fetchUserImageDisposable = getUserImage().subscribe()
        
        fetchUserImageDisposable.disposed(by: disposeBag)
        
        setAvailableNetsData()
        
        viewDispatchItems.isHidden = true
        lblStateTopAnchgor.constant = -63
        
        let longTitleLabel = UILabel()
        longTitleLabel.text = "Gofernets"
        longTitleLabel.textColor = .white
        longTitleLabel.sizeToFit()
        
        let leftItem = UIBarButtonItem(customView: longTitleLabel)
        self.navigationItem.leftBarButtonItem = leftItem
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let view = UIApplication.shared.keyWindow {
            view.addSubview(doneButton)
            setupButton()
        }
    }
    
    func setupButton() {
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            doneButton.widthAnchor.constraint(equalToConstant: 44)
        ])
        doneButton.layer.cornerRadius = 22
        doneButton.layer.masksToBounds = true
    }
    
    //MARK: - SegmentUI
    
    private func setupCollectionView(){
        cvVehicleType.delegate = self
        cvVehicleType.dataSource = self
        cvVehicleType.register(UINib(nibName: "ItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ItemCollectionViewCell")
        cvVehicleType.allowsMultipleSelection = true
        cvVehicleType.reloadData()
        
        
        cvStates.delegate = self
        cvStates.dataSource = self
        cvStates.register(UINib(nibName: "ItemCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ItemCollectionViewCell")
        cvStates.allowsMultipleSelection = true
        cvStates.reloadData()
    }
    
    //MARK: - Button actions
    
    @IBAction func btnMoreAction(_ sender: UIButton) {
        dropDown.dataSource = ["Restore backup file", "Restore Messages Database"]
        dropDown.anchorView = sender
        //        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        //        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
        //            guard let _ = self else { return }
        //            sender.setTitle(item, for: .normal)
        //
        //        }
    }
    
    
    @IBAction func segmentVendorAction(_ sender: UISegmentedControl) {
        if segmentVendor.selectedSegmentIndex == 0 {
            operatorView.isHidden = true
            venderView.isHidden = false
            scrollView.isScrollEnabled = false
        } else {
            operatorView.isHidden = false
            venderView.isHidden = true
            scrollView.isScrollEnabled = true
        }
    }
    
    @IBAction func segmentOperatorGenderAction(_ sender: UISegmentedControl) {
    }
//    @IBAction func segmentVendorGenderAction(_ sender: UISegmentedControl) {
//    }
    
    @IBAction func segmentBusinesstypeAction(_ sender: UISegmentedControl) {
        if segmentBusiness.selectedSegmentIndex == 0 {
            viewIndependetItems.isHidden = false
            viewDispatchItems.isHidden = true
            lblStateTopAnchgor.constant = -63
            btnCeoImage.setTitle("UPLOAD GOVT ISSUED ID CARD", for: .normal)
            lblCeoTitle.text = "Government issued ID Card"
            lblIdTitle.text = "Utility Bill"
            btnIdImage.setTitle("UPLOAD UTILITY BILL", for: .normal)
        } else {
            viewIndependetItems.isHidden = true
            viewDispatchItems.isHidden = false
            lblStateTopAnchgor.constant = 0
            btnCeoImage.setTitle("UPLOAD CEO'S RECENT PICTURE", for: .normal)
            lblCeoTitle.text = "Take a selfie or upload a recent picture"
            lblIdTitle.text = "Government issued ID Card"
            btnIdImage.setTitle("UPLOAD ID", for: .normal)
        }
    }
    
    @IBAction func segmentHouseOfficeAction(_ sender: UISegmentedControl) {
    }
    
    @IBAction func segmentPerishableAction(_ sender: UISegmentedControl) {
    }
    @IBAction func segmentPickupDeliveryAction(_ sender: UISegmentedControl) {
    }
    
    @objc private func  doneTapped() {
        Permissions.requestContactsPermissions { (_) in
            self.completeSetup()
        }
    }
    
    fileprivate func goToRoot() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "RootNavController") as! RootNavController
        self.dismiss(animated: false) {
            self.view.window?.rootViewController = newViewController
        }
    }
    private func saveUserInfo(userName: String, thumb: String, photo: String, localPhoto: String) {
        let user = User()
        user.uid = FireManager.getUid()
        user.userName = userName
        user.thumbImg = thumb
        user.photo = photo
        user.isIdVerified = false
        
        user.userLocalPhoto = localPhoto
        user.fullName = txtFullName.text ?? ""
        user.homeAddress = txtHomeAddress.text ?? ""
        
        if segmentVendor.selectedSegmentIndex == 0{
            user.address = txtVenderAddress.text ?? ""
            user.email = txtVenderEmail.text ?? ""
            user.phone = txtVenderExtraPhoneNumber.text ?? ""
//            user.gender = segmentVendorGender.selectedSegmentIndex == 0 ? "Male" : "Female"
            UserDefaultsManager.setPhoneNumber(txtVenderExtraPhoneNumber.text ?? "")
        }else{
            user.address = txtAddress.text ?? ""
            user.phone = txtPhoneNumber.text ?? ""
            UserDefaultsManager.setPhoneNumber(txtPhoneNumber.text ?? "")
//            user.gender = segmentGender.selectedSegmentIndex == 0 ? "Male" : "Female"
        }
        
        user.bio = txtYourBusiness.text ?? ""
        user.businessName = txtBusinessName.text ?? ""
        user.businessType = ""
        
        user.userType = segmentVendor.selectedSegmentIndex == 0 ? "Vendor" : "operator"
        user.house_office = segmentHouseOffice.selectedSegmentIndex == 0 ? "House" : "Office"
        user.instagram = txtInstagram.text ?? ""
        user.facebook = txtFacebook.text ?? ""
        user.twitter = txtTwitter.text ?? ""
        
        user.deliverPerishable = segmentPerishableFood.selectedSegmentIndex == 0 ? true : false
        user.express_pickup = segmentPickupDelivery.selectedSegmentIndex == 0 ? true : false
        
        user.netsAvailable = netsAvailable
        
        var vehicleTypes: String = ""
        if let indexpaths = cvVehicleType.indexPathsForSelectedItems {
            for index in indexpaths {
                vehicleTypes.append("\(arrOfVehicleTypes[index.row]), ")
            }
        }
        
        user.vehicleType = vehicleTypes
        
        var stateList: String = ""
        if let indexpaths = cvStates.indexPathsForSelectedItems {
            for index in indexpaths {
                stateList.append("\(arrOfStates[index.row]), ")
            }
        }
        
        user.statelist = stateList
        
        let defaultStatus = Strings.default_status
        
        user.status = defaultStatus
        
        //save current uid so the ShareExtension can read/check the current user's info
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: CurrentUid(uid: FireManager.getUid()), update: true)
        
        //save current user info
        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user, update: true)
    }
    
    private func completeSetup() {
        if txtYourName.text?.isEmpty ?? true {
            showAlert(type: .error, message: Strings.full_name_empty)
            return
        }
        if segmentVendor.selectedSegmentIndex == 1{
            if segmentBusiness.selectedSegmentIndex == 0{
                if txtFullName.text?.isEmpty ?? true {
                    showAlert(type: .error, message: Strings.home_address_empty)
                    return
                }
                
                if txtHomeAddress.text?.isEmpty ?? true {
                    showAlert(type: .error, message: Strings.business_name_empty)
                    return
                }
                
                if isGovIdVerified == false{
                    showAlert(type: .error, message: "Please select a Government ID")
                    return
                }
                
                if isBillVerified == false{
                    showAlert(type: .error, message: "Please select a Utility Bill")
                    return
                }
                
            }else{
                if txtBusinessName.text?.isEmpty ?? true {
                    showAlert(type: .error, message: Strings.business_name_empty)
                    return
                }
                
                if txtAddress.text?.isEmpty ?? true {
                    showAlert(type: .error, message: Strings.address_empty)
                    return
                }
                
                if txtYourBusiness.text?.isEmpty ?? true {
                    showAlert(type: .error, message: Strings.your_business_empty)
                    return
                }
                
                if isCeoImageVerified == false{
                    showAlert(type: .error, message: "Please select a CeoImage")
                    return
                }
                
                if isDocumnetIdVerified == false{
                    showAlert(type: .error, message: "Please select a Id")
                    return
                }
            }
            
            
            if txtPhoneNumber.text?.isEmpty ?? true {
                showAlert(type: .error, message: Strings.phone_number_empty)
                return
            }
            
            var selectedVehicleType = [String]()
            if let indexpaths = cvVehicleType.indexPathsForSelectedItems {
                for index in indexpaths {
                    selectedVehicleType.append(arrOfVehicleTypes[index.row])
                }
            }
            
            if selectedVehicleType.count == 0 && segmentVendor.selectedSegmentIndex == 1 {
                showAlert(type: .error, message: Strings.select_atleast_one_vehicle_type)
                return
            }
            
            var selectedState = [String]()
            if let indexpaths = cvStates.indexPathsForSelectedItems {
                for index in indexpaths {
                    selectedState.append(arrOfStates[index.row])
                }
            }
            if selectedState.count == 0 && segmentVendor.selectedSegmentIndex == 1 {
                showAlert(type: .error, message: Strings.select_atleast_one_State)
                return
            }
            
        } else {
            if txtVenderAddress.text?.isEmpty ?? true{
                showAlert(type: .error, message: Strings.vender_address_empty)
                return
            }
            if txtVenderExtraPhoneNumber.text?.isEmpty ?? true{
                showAlert(type: .error, message: Strings.extra_phone_number_empty)
                return
            }
            
        }
        
        
        let userName = txtYourName.text ?? ""
        
        showLoadingViewAlert()
        
        //if the user picked a new image
        
        if let image = pickedImage {
            //upload this image
            FireManager.changeMyPhotoObservable(image: image, appRealm: appRealm)
                .flatMap { (thumb, localUrl, photoUrl) -> Observable<DatabaseReference> in
                    
                    let userDict = self.getUserInfoDict(userName: userName, photoUrl: photoUrl, thumb: thumb, filePath: localUrl)
                    
                    //save user info locally
                    self.saveUserInfo(userName: userName, thumb: thumb, photo: photoUrl, localPhoto: localUrl)
                    
                    if self.segmentVendor.selectedSegmentIndex == 0{
                        let countryCode = ContactsUtil.extractCountryCodeFromNumber(self.txtVenderExtraPhoneNumber.text ?? "")
                        UserDefaultsManager.setCountryCode(countryCode)
                    }else {
                        let countryCode = ContactsUtil.extractCountryCodeFromNumber(self.txtPhoneNumber.text ?? "")
                        UserDefaultsManager.setCountryCode(countryCode)
                    }
                    
                    //set default country code
                    
                    //save user info in Firebase
                    return FireConstants.usersRef.child(FireManager.getUid()).rx.updateChildValues(userDict).asObservable()
                    
                }.flatMap { ref -> Observable<([User], [String], Void)> in
                    //fetch previous groups if exists
                    let fetchGroups = GroupManager.fetchUserGroups()
                    //fetch previous broadcasts if exists
                    let fetchBroadcasts = BroadcastManager.fetchBroadcasts(uid: FireManager.getUid())
                    //combine both observables and execute them
                    
                    let subscribeToTopic = self.subscribeToHisOwnTopic()
                    let observables = Observable.zip(fetchGroups, fetchBroadcasts, subscribeToTopic)
                    
                    return observables
                }.subscribe(onError: { error in
                    self.hideAndShowAlert()
                }, onCompleted: {
                    //set the user info saved to true
                    UserDefaultsManager.setUserInfoSaved(true)
                    self.goToRoot()
                }).disposed(by: disposeBag)
            
        } else {
            // if fetching the user's image on server succeed
            if currentUserPhotoUrl != "" {
                
                //download this image locally
                FireManager.downloadPhoto(photoUrl: self.currentUserPhotoUrl).map { photo -> String in
                    self.saveUserInfo(userName: userName, thumb: self.currentUserPhotoThumb, photo: self.currentUserPhotoUrl, localPhoto: photo)
                    
                    if self.segmentVendor.selectedSegmentIndex == 0{
                        let countryCode = ContactsUtil.extractCountryCodeFromNumber(self.txtVenderExtraPhoneNumber.text ?? "")
                        UserDefaultsManager.setCountryCode(countryCode)
                    }else{
                        let countryCode = ContactsUtil.extractCountryCodeFromNumber(self.txtPhoneNumber.text ?? "")
                        UserDefaultsManager.setCountryCode(countryCode)
                    }
                    
                   
                    return photo
                }.flatMap { photo -> Observable<([User], [String], DatabaseReference, Void)> in
                    let fetchGroups = GroupManager.fetchUserGroups()
                    let fetchBroadcasts = BroadcastManager.fetchBroadcasts(uid: FireManager.getUid())
                    
                    let userDict = self.getUserInfoDict(userName: userName, photoUrl: self.currentUserPhotoUrl, thumb: self.currentUserPhotoThumb, filePath: photo)
                    
                    //set user info in Firebase
                    let setUserInfo = FireConstants.usersRef.child(FireManager.getUid()).rx.updateChildValues(userDict).asObservable()
                    let subscribeToTopic = self.subscribeToHisOwnTopic()
                    return Observable.zip(fetchGroups, fetchBroadcasts, setUserInfo, subscribeToTopic)
                    
                }.subscribe(onError: { error in
                    self.hideAndShowAlert()
                }, onCompleted: {
                    UserDefaultsManager.setUserInfoSaved(true)
                    self.goToRoot()
                }).disposed(by: disposeBag)
                
            } else {
                //cancel old process if exists to start a new one
                fetchUserImageDisposable.dispose()
                
                let fetchGroups = GroupManager.fetchUserGroups()
                let fetchBroadcasts = BroadcastManager.fetchBroadcasts(uid: FireManager.getUid())
                
                
                //if the old photo not exists on server(this is the first time)
                //download the 'defaultUserProfilePhoto'
                getDefaultUserProfilePhoto()
                    .map { tuple -> [String: Any] in
                        let localPhotoUrl = tuple.0
                        let photoUrl = tuple.1
                        let thumb = tuple.2
                        
            
                        
                        let user = User()
                        user.uid = FireManager.getUid()
                        user.userName = userName
                        user.thumbImg = thumb
                        user.photo = photoUrl
                        user.userLocalPhoto = localPhotoUrl
                        if self.segmentVendor.selectedSegmentIndex == 0{
                            user.phone = self.txtVenderExtraPhoneNumber.text ?? ""
                        }else{
                            user.phone = self.txtPhoneNumber.text ?? ""
                        }
                        
                        user.netsAvailable = self.netsAvailable
                        
                        
                        RealmHelper.getInstance(appRealm).saveObjectToRealm(object: user, update: true)
                        
                        self.saveUserInfo(userName: userName, thumb: thumb, photo: photoUrl, localPhoto: localPhotoUrl)
                        
                        if self.segmentVendor.selectedSegmentIndex == 0 {
                            let countryCode = ContactsUtil.extractCountryCodeFromNumber(self.txtVenderExtraPhoneNumber.text ?? "")
                            
                            UserDefaultsManager.setCountryCode(countryCode)
                        }else{
                            let countryCode = ContactsUtil.extractCountryCodeFromNumber(self.txtPhoneNumber.text ?? "")
                            
                            UserDefaultsManager.setCountryCode(countryCode)
                        }
                        
                        
                        let userDict = self.getUserInfoDict(userName: userName, photoUrl: photoUrl, thumb: thumb, filePath: localPhotoUrl)
                        
                        return userDict
                    }.flatMap { userDict -> Observable<([User], [String], DatabaseReference, Void)> in
                        let setUserInfo = FireConstants.usersRef.child(FireManager.getUid()).rx.updateChildValues(userDict).asObservable()
                        let subscribeToTopic = self.subscribeToHisOwnTopic()
                        
                        let observables = Observable.zip(fetchGroups, fetchBroadcasts, setUserInfo, subscribeToTopic)
                        return observables
                    }.subscribe(onError: { error in
                        self.hideAndShowAlert()
                    }, onCompleted: {
                        UserDefaultsManager.setUserInfoSaved(true)
                        self.goToRoot()
                    }).disposed(by: self.disposeBag)
                
            }
        }
    }
    
    //MARK: - Button Actions
    @IBAction func btnUploadCEOImgAction(_ sender: Any) {
        if segmentBusiness.selectedSegmentIndex == 0 {
            ImagePickerManager().pickImage(self){ image in
                //here is the image
                self.lblUploadCEOImg.text = "Goverment Id.png"
                //            self.ceoImageData = image.toDataPng(compress: true)!
                FirebaseManager.sharedFirebaseManager.uploadMedia("", UploadImageType.govId, uploadData: image.toDataPng(compress: true)!) { error, url in
                    self.isGovIdVerified = true
                }
            }
        } else{
            ImagePickerManager().pickImage(self){ image in
                //here is the image
                //            self.businessImageData = image.toDataPng(compress: true)!
                self.lblUploadCEOImg.text = "Ceo Image.png"
                FirebaseManager.sharedFirebaseManager.uploadMedia("", UploadImageType.ceoImage, uploadData: image.toDataPng(compress: true)!) { error, url in
                    self.isCeoImageVerified = true
                }
            }
            
        }
        
    }
    
    @IBAction func btnUploadIDAction(_ sender: UIButton) {
        if segmentBusiness.selectedSegmentIndex == 0{
            ImagePickerManager().pickImage(self){ image in
                //here is the image
                self.lblUploadCEOImg.text = "Bill Image.png"
                //            self.ceoImageData = image.toDataPng(compress: true)!
                FirebaseManager.sharedFirebaseManager.uploadMedia("", UploadImageType.utilityBill, uploadData: image.toDataPng(compress: true)!) { error, url in
                    self.isBillVerified = true
                }
            }
        }else{
            ImagePickerManager().pickImage(self){ image in
                //here is the image
                //            self.businessImageData = image.toDataPng(compress: true)!
                self.lblUploadIDImg.text = "Id.png"
                FirebaseManager.sharedFirebaseManager.uploadMedia("", UploadImageType.idImage, uploadData: image.toDataPng(compress: true)!) { error, url in
                    self.isDocumnetIdVerified = true
                }
            }
        }
        
    }
    
    @IBAction func btnUtilityBillAction(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            //here is the image
            //            self.utilityImageData = image.toDataPng(compress: true)!
            self.lblUtilityBillImg.text = "Bill.png"
            FirebaseManager.sharedFirebaseManager.uploadMedia("", UploadImageType.idImage, uploadData: image.toDataPng(compress: true)!) { error, url in
            }
        }
    }
    
    private func getUserInfoDict(userName: String, photoUrl: String, thumb: String, filePath: String? = nil) -> [String: Any] {
        var dict = [String: Any]()
        dict["photo"] = photoUrl
        dict["name"] = userName
        dict["userType"] = segmentVendor.selectedSegmentIndex == 0 ? "Vendor" : "operator"
        dict["businessName"] = txtBusinessName.text ?? ""
        
        if segmentVendor.selectedSegmentIndex == 0{
            dict["email"] = txtVenderEmail.text ?? ""
            dict["address"] = txtVenderAddress.text ?? ""
            dict["phone"] = txtVenderExtraPhoneNumber.text ?? ""
//            dict["gender"] = segmentVendorGender.selectedSegmentIndex == 0 ? "Male" : "Female"
        }else{
            dict["email"] = emailTextOperator.text ?? ""
            dict["address"] = txtAddress.text ?? ""
            dict["phone"] = txtPhoneNumber.text ?? ""
            dict["gender"] = segmentGender.selectedSegmentIndex == 0 ? "Male" : "Female"
            
        }
        
        dict["isIdVerified"] = false
        dict["bio"] = txtYourBusiness.text ?? ""
        dict["instagram"] = txtInstagram.text ?? ""
        dict["facebook"] = txtFacebook.text ?? ""
        dict["twitter"] = txtTwitter.text ?? ""
        
        var vehicleTypes: String = ""
        if let indexpaths = cvVehicleType.indexPathsForSelectedItems {
            for index in indexpaths {
                vehicleTypes.append("\(arrOfVehicleTypes[index.row]), ")
            }
        }
        
        dict["vehicleType"] = vehicleTypes
        
        var stateList: String = ""
        if let indexpaths = cvStates.indexPathsForSelectedItems {
            for index in indexpaths {
                stateList.append("\(arrOfStates[index.row]), ")
            }
        }
        
        dict["statelist"] = stateList
        dict["house_office"] = segmentHouseOffice.selectedSegmentIndex == 0 ? "House" : "Office"
        dict["deliverPerishable"] = segmentPerishableFood.selectedSegmentIndex == 0 ? true : false
        dict["express_pickup"] = segmentPickupDelivery.selectedSegmentIndex == 0 ? true : false
        
//        dict["phone"] = FireManager.number!
        dict["thumbImg"] = thumb
        
        dict["businessType"] = ""
        
        dict["netsAvailable"] = self.netsAvailable
        
        let defaultStatus = Strings.default_status
        dict["status"] = defaultStatus
        
        return dict
        
    }
    
    private func hideAndShowAlert() {
        self.hideLoadingViewAlert {
            self.showAlert(type: .error, message: Strings.error)
        }
    }
    
    @objc private func userImgTapped() {
        let permission: Permission = .photos
        
        let alert = permission.deniedAlert // or permission.disabledAlert
        alert.title = "In order to set an image please allow image access."
        alert.message = nil
        alert.cancel = Strings.cancel
        alert.settings = Strings.settings
        
        permission.deniedAlert = alert
        
        permission.request { status in
            self.OpenPhotosCamera()
        }
    }
    
    func OpenPhotosCamera(){
        let alert: UIAlertController = UIAlertController(title:"", message:"select source", preferredStyle:.actionSheet)
        alert.addAction(UIAlertAction(title:"Camera", style:.default, handler:{ action in
            let vc = CropImageRequest.getRequest { (image, asset) in
                if let image = image {
                    self.indicatorView.isHidden = false
                    self.pickedImage = image
                    self.imgUser.image = image
                    self.dismiss(animated: true, completion: nil)
                }
            }
            self.present(vc, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title:"Photo Album", style:.default, handler:{ action in
            self.OpenGallary()
        }))
        alert.addAction(UIAlertAction(title:"Cancel", style:.cancel, handler:nil))
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.frame.origin.y, width: 0, height: 0)
        }
        self.present(alert, animated:true, completion:nil)
    }
    
    func OpenGallary(){
        
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func loadImageFromUrl(_ url: URL) {
        self.imgUser.kf.setImage(with: url) { result in
            switch result {
            case .success(let value):
                
                self.indicatorView.isHidden = true
                
            case .failure(let error): break
                
            }
        }
    }
    
    private func getUserImage() -> Observable<(String, String)> {
        
        return FireConstants.usersRef.child(FireManager.getUid())
            .rx.observeSingleEvent(.value).asObservable().map { snapshot -> (String, String) in
                if let photoUrl = snapshot.childSnapshot(forPath: "photo").value as? String, let thumb = snapshot.childSnapshot(forPath: "thumbImg").value as? String {
                    
                    self.loadImageFromUrl(URL(string: photoUrl)!)
                    self.currentUserPhotoUrl = photoUrl
                    self.currentUserPhotoThumb = thumb
                    return (photoUrl, thumb)
                } else {
                    self.indicatorView.isHidden = true
                    
                    return ("", "")
                }
            }
    }
    
    private func setAvailableNetsData() {
        
        FireConstants.usersRef.child(FireManager.getUid()).observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                self.netsAvailable = 0
                return
            }
            let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int
            
            self.netsAvailable = nets ?? 0
        }
    }
    
    
    //this will fetch the 'defaultUserProfilePhoto' on the server
    //it will be called if this user did not choose an image and he does not have a previous image on the server
    private func getDefaultUserProfilePhoto() -> Observable<(String, String, String)> {
        return FireConstants.mainRef.child("defaultUserProfilePhoto").rx.observeSingleEvent(.value).asObservable().flatMap { snap -> Observable<(URL, String)> in
            if let imgUrl = snap.value as? String {
                
                if let url = URL(string: imgUrl) {
                    self.loadImageFromUrl(url)
                }
                let filePath = DirManager.generateUserProfileImage()
                
                return FireConstants.storage.reference(forURL: imgUrl).rx.write(toFile: filePath).map { ($0, imgUrl) }
            }
            return Observable.error(NSError(domain: "user did not upload default user profile photo", code: -5, userInfo: nil))
            
        }.map { tuple -> (String, String, String) in
            
            
            let filePath = tuple.0.path
            let imgUrl = tuple.1
            
            let img = UIImage(contentsOfFile: filePath)
            let thumb = img!.toProfileThumbImage.circled().toBase64StringPng()
            self.currentUserPhotoThumb = thumb
            
            return (filePath, imgUrl, thumb)
            
        }
    }
    
    //so when this user sends a message to the group he will not receive it.
    private func subscribeToHisOwnTopic() -> Observable<Void> {
        return Messaging.messaging().subscribeToTopicRx(topic: FireManager.getUid()).asObservable()
    }
    
    //MARK: - Imagepicker methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            self.dismiss(animated: true, completion: {
                self.indicatorView.isHidden = false
                self.pickedImage = pickedImage
                self.imgUser.image = pickedImage
            })
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

extension SetupUserVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == cvVehicleType{
            return arrOfVehicleTypes.count
        }else {
            return arrOfStates.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCollectionViewCell", for: indexPath) as! ItemCollectionViewCell
        if collectionView == cvVehicleType{
            cell.textLabel.text = arrOfVehicleTypes[indexPath.row]
        }else{
            cell.textLabel.text = arrOfStates[indexPath.row]
        }
        
        cell.textLabel.textColor = UIColor.white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 40)
    }
}
