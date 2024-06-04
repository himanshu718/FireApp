//
//  AddVendorOrderViewController.swift
//  FireApp
//
//  Created by Kartik Gupta on 14/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseFunctions
import Firebase
import FirebaseFirestore
import CoreLocation
import MapKit
import LocationPicker
import ContextMenu

enum SelectedLocationButton {
    case pickUp
    case delivery
}

class AddVendorOrderViewController: UIViewController, mapViewDelegate, ContextMenuDelegate, ContextMenuSelectStateDelegate {
    
//    var pickupLoc: CLLocationCoordinate2D!
//    var deliveryLoc: CLLocationCoordinate2D!
    
    var selectedLocationBtn:  SelectedLocationButton!
    var user: User!
    
    var imageData: Data? = nil
    
    //MARK: - Outlets
//    @IBOutlet weak var deliveryLocationBtn: UIButton!
//    @IBOutlet weak var sizeDetailsTxtField: UITextField!
//    @IBOutlet weak var weightDetailsTxtField: UITextField!
    
    @IBOutlet weak var priceOfferedTxtField: UITextField!
    @IBOutlet weak var deliveryLocTxtField: UITextField!
    @IBOutlet weak var pickupLoctxtField: UITextField!
    @IBOutlet weak var pickLocationButton: UIButton!
    @IBOutlet weak var orderDetailTxtField: UITextField!
    @IBOutlet weak var orderImageView: UIImageView!
    
    @IBOutlet weak var addImageBtn: UIButton!
    @IBOutlet weak var btnLocation: UIButton!
    @IBOutlet weak var btnVehicleType: UIButton!
    
    @IBOutlet weak var btnAddImageTopAncher: NSLayoutConstraint!
    
    @IBOutlet weak var btnAddOrder: UIButton!
    
    //MARK: - Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
//        pickLocationButton.setTitle("", for: .normal)
//        deliveryLocationBtn.setTitle("", for: .normal)
//        pickLocationButton.isEnabled = false
//        deliveryLocationBtn.isEnabled = false
//        pickLocationButton.isHidden = true
//        deliveryLocationBtn.isHidden = true
        btnAddOrder.layer.cornerRadius = 18
        btnAddOrder.clipsToBounds = true
        addImageBtn.layer.cornerRadius = 16
        addImageBtn.clipsToBounds = true
        btnAddOrder.isEnabled = true


        orderImageView.isHidden = true
        setNavbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(hexString: "#2196f5")
        self.navigationController?.navigationBar.tintColor = UIColor.white

    }
    
    //MARK: - Button Actions
    @IBAction func btnVehicleTypeAction(_ sender: UIButton) {
        let vc = MenuViewController()
        vc.delegate = self
        vc.isWhichDropDown = "Vehicle Type"
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: vc,
            options: ContextMenu.Options(
                containerStyle: ContextMenu.ContainerStyle(
                    backgroundColor: .white
                ),
                menuStyle: .minimal,
                hapticsStyle: .heavy
            ),
            sourceView: btnVehicleType,
            delegate: self
        )
    }
    @IBAction func btnLocationAction(_ sender: UIButton) {
        let vc = MenuViewController()
        vc.delegate = self
        vc.isWhichDropDown = "Location"
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: vc,
            options: ContextMenu.Options(
                containerStyle: ContextMenu.ContainerStyle(
                    backgroundColor: .white
                ),
                menuStyle: .minimal,
                hapticsStyle: .heavy
            ),
            sourceView: btnLocation,
            delegate: self
        )
    }
    
    @IBAction func addOrderBtbtapped (_ sender: Any) {
        if orderDetailTxtField.text == ""{
            self.showAlert(type: .error, message: "Please enter parcel name")
        }else if pickupLoctxtField.text == ""{
            self.showAlert(type: .error, message: "Please enter pickup location")
        }else if deliveryLocTxtField.text == ""{
            self.showAlert(type: .error, message: "Please enter delivery location")
        }else if btnLocation.title(for: .normal) == ""{
            self.showAlert(type: .error, message: "Please select location")
        }else {
            saveOrderData()
        }
    }
    
    @IBAction func addImageBtnTapped(_ sender: Any) {
        ImagePickerManager().pickImage(self){ image in
            //here is the image
            self.orderImageView.isHidden = false
           
            self.orderImageView.image = image
            let imgConstraint = self.orderImageView.frame.origin.x + self.orderImageView.frame.width + 20
            self.btnAddImageTopAncher.constant = imgConstraint
            self.imageData = image.toDataPng(compress: true)
        }
    }
    
    @IBAction func deliveryLocationTapped(_ sender: Any) {
        selectedLocationBtn = .delivery
        openMapView()
    }
    
    @IBAction func pickUpLocationTapped(_ sender: Any) {
        selectedLocationBtn = .pickUp
        openMapView()
    }
    
    //MARK: ContextMenuDelegate
    func didSelect(itemType: String, isWhichDropDown: String) {
        if isWhichDropDown == "Location"{
            btnLocation.setTitle(itemType, for: .normal)
        }else if isWhichDropDown == "Vehicle Type"{
            btnVehicleType.setTitle(itemType, for: .normal)
        }
    }
    
    func contextMenuWillDismiss(viewController: UIViewController, animated: Bool) {
    }

    func contextMenuDidDismiss(viewController: UIViewController, animated: Bool) {
    }
    
    //MARK: - Custom Functions
    fileprivate func setOrderData(_ order: Order, _ ref: DocumentReference, _ loading: LoadingViewController) {
        do {
            let encodedJson = try order.jsonData()
            if let data = try JSONSerialization.jsonObject(with: encodedJson, options: .mutableLeaves) as? [String: Any] {
                ref.setData(data) { [weak self] err in
                    guard let self = self else { return }
                    loading.dismiss()
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        
                        if order.state == "Lagos"{
                            self.fecthLagosUser(orderName: orderDetailTxtField.text ?? "")
//                            pushNotificationCreateUserId(
//                                userId: FireManager.getUid(),
//                                userName: "\(orderDetailTxtField.text ?? "") New Order",
//                                message: """
//                                    Pickup: \(pickupLoctxtField.text ?? "")
//                                    Delivery: \(deliveryLocTxtField.text ?? "")
//                                    Parcel: \(orderDetailTxtField.text ?? "")
//                                """, type: Config.Type_Of_Create
//                            )
                        }
                        
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        } catch {
            print("Error")
        }
    }
    
    func saveOrderData() {
        btnAddOrder.isEnabled = false
        guard let orderDescription = orderDetailTxtField.text, let pickupLocation = pickupLoctxtField.text, let deliveryLocation = deliveryLocTxtField.text, let priceOffered = priceOfferedTxtField.text, let state = btnLocation.title(for: .normal),let vehicleType = btnVehicleType.title(for: .normal) else {
            showAlert(type: .error, message: "Please fill up all details")
            return
        }
          
        let loading = LoadingViewController()
        loading.show(text: "Order Posting...".localized)
        
        let ref = Firestore.firestore().collection(Config.COLLECTION_ORDERS).document()
        let timeStamp = Int64(Date().timeIntervalSince1970) * 1000
        
        if let imageData = imageData {
            FirebaseManager.sharedFirebaseManager.uploadMedia(ref.documentID, .orderImage, uploadData: imageData) { error, url in
                if error == nil {
                    let order = Order.init(status: "CREATED", assignedAtPrice: nil, assignedBidId: nil, assignedUserId: nil, assignedUserName: nil, bidderIDs: nil, completed: false, delivery: deliveryLocation, image: url, netsRequired: 2, orderDiscription: orderDescription, orderId: ref.documentID, pickup: pickupLocation, price: Int(priceOffered), size:  "", timestamp: timeStamp, vendorId: FireManager.getUid(), vendorName: self.user.userName, weight: "", state: state, vendorReview: "", vendorRating: 0.0, operatorReview: "", operatorRating: 0.0, vehicleType: vehicleType)
                    self.setOrderData(order, ref, loading)
                    if order.state == "Lagos"{
//                        self.fecthLagosUser(orderName: order.orderDiscription ?? "")
                    }
                } else {
                    print("issue with Image uploading")
                }
            }
        } else {
            let order = Order.init(status: "CREATED", assignedAtPrice: nil, assignedBidId: nil, assignedUserId: nil, assignedUserName: nil, bidderIDs: nil, completed: false, delivery: deliveryLocation, image: nil, netsRequired: 2, orderDiscription: orderDescription, orderId: ref.documentID, pickup: pickupLocation, price: Int(priceOffered), size: "", timestamp: timeStamp, vendorId: FireManager.getUid(), vendorName: user.userName, weight: "", state: state, vendorReview: "", vendorRating: 0.0, operatorReview: "", operatorRating: 0.0, vehicleType: vehicleType)
            setOrderData(order, ref, loading)
        }
    }
    
    func fecthLagosUser(orderName: String){
        FireConstants.usersRef.observeSingleEvent(of: .value) { snapshot in
                
                guard let dataSnapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                    return
                }
                
                for data in dataSnapshot {
                    if let statelist = data.childSnapshot(forPath: "statelist").value as? String, statelist.contains("Lagos") {
                        print("USERS_Send== \(data.key)")
                        
                        if FireManager.getUid() != data.key {
                            pushNotificationCreateUserId(userId: data.key, userName: " New Order : \(orderName)", message: " Pickup: \(self.pickupLoctxtField.text ?? "")\nDelivery: \(self.deliveryLocTxtField.text ?? "")", type: Config.Type_Of_Create)
                        }
                    }
                }
            }
    }
    
    func openMapView() {
        let mapViewVC = MapViewController(nibName: "MapViewController", bundle: nil)
        mapViewVC.delegate = self
        self.navigationController?.pushViewController(mapViewVC, animated: true)
    }
    
    func selectedLocation(location: CLLocationCoordinate2D) {
        switch selectedLocationBtn {
        case .pickUp:
            let address = CLGeocoder.init()
            address.reverseGeocodeLocation(CLLocation.init(latitude: location.latitude, longitude: location.longitude)) { (places, error) in
                if error == nil{
                    if let place = places, place.count > 0 {
                        self.pickupLoctxtField.text! = self.getAddress(place[0])
                        print(place)
                    }
                }
            }
        default:
            let address = CLGeocoder.init()
            address.reverseGeocodeLocation(CLLocation.init(latitude: location.latitude, longitude: location.longitude)) { (places, error) in
                if error == nil{
                    if let place = places, place.count > 0 {
                        self.deliveryLocTxtField.text! = self.getAddress(place[0])
                        print(place)
                        //here you can get all the info by combining that you can make address
                    }
                }
            }
        }
    }
    
    func getAddress(_ pm: CLPlacemark) -> String {
        
        var addressString : String = ""
        if pm.subLocality != nil {
            addressString = addressString + pm.subLocality! + ", "
        }
        if pm.thoroughfare != nil {
            addressString = addressString + pm.thoroughfare! + ", "
        }
        if pm.locality != nil {
            addressString = addressString + pm.locality! + ", "
        }
        if pm.country != nil {
            addressString = addressString + pm.country! + ", "
        }
        if pm.postalCode != nil {
            addressString = addressString + pm.postalCode! + " "
        }
        
        return addressString
    }
    
    func setNavbar(){
        if #available(iOS 13.0, *) {
            // Create a custom navigation bar appearance for iOS 13 and later
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = UIColor.init(hexString: "#2196f5")
            navigationBarAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            navigationController?.navigationBar.standardAppearance = navigationBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        } else {
            // For iOS versions prior to 13
            navigationController?.navigationBar.barTintColor = UIColor.init(hexString: "#2196f5")
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
}
