//
//  OperatorViewController.swift
//  FireApp
//
//  Created by Kartik Gupta on 03/12/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import DropDown
import RealmSwift

class OperatorViewController: UIViewController {
    var chats: Results<Chat>!
    var orderList: [Order] = []
    var user: User!
    let loading = LoadingViewController()
    var disposeBag = DisposeBag()
    var netbalance = 0
    
    var isCreated = false
    var isAssignedToMeSelected = false
    var isCompleted = false
    
    var score = CGFloat()
    var selectedOrder: Order!
    var verifyIdStatus: Bool = false
    
   
    
    //MARK: - Outlets
    @IBOutlet weak var viewBlur: UIView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewStarRate: UIView!
    @IBOutlet weak var txtReview: UITextField!
    @IBOutlet weak var lblParcelName: UILabel!
    
    @IBOutlet weak var btnOK: UIButton!
    @IBOutlet weak var viewBoard: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        viewBlur.isHidden =  true
        viewBoard.layer.cornerRadius = 8
        viewBoard.layer.masksToBounds = true

        tableView.registerCellNib(cellClass: OperatorOrderCell.self)
        tableView.registerCellNib(cellClass: AssignedBidCell.self)
        tableView.registerCellNib(cellClass: MyBidCell.self)

        tableView.delegate = self
        tableView.dataSource = self
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())

        getOrdersForDeliveryOperator()
        
        
        checkVerifyId()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    

    
    
    func getOrdersForDeliveryOperator() {
        print("user id ---\(user.uid)")
        self.orderList = []
        
        loading.show(text: "Please wait...".localized)
        FirebaseManager.sharedFirebaseManager.getOrdersForDeliveryOperator(isCreated, isAssignedToMeSelected, isCompleted, completion: { (documents, error) in
            self.orderList = []
            if documents?.count ?? 0 > 0 {
                for document in documents! {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document, options: .prettyPrinted)
                        self.orderList.append(try Order.init(data: data))
                        
                    } catch {
                        print("JSONSerialization error:", error)
                    }
                }
            }
            
            var arrOfStates = [String]()
            if let stateList = self.user?.statelist as? String {
                let result = stateList.components(separatedBy: ", ")
                arrOfStates = result
            }

            var stateData = [String]()
            for i in arrOfStates {
                stateData.append(i)
            }
            
            var arrOfVehicles = [String]()
            if let vehicle_type = self.user?.vehicleType as? String {
                let result = vehicle_type.components(separatedBy: ", ")
                arrOfVehicles = result
            }

            var vehiclesData = [String]()
            for i in arrOfVehicles {
                vehiclesData.append(i)
            }
            
            self.orderList = self.orderList.filter { item in
                if item.vendorId == self.user.uid {
                    return true
                } else {
                    guard let state = item.state else {
                        if vehiclesData.contains("Anyone") {
                            return true
                        } else {
                            guard let vehicle = item.vehicleType else {
                                return true
                            }
                            return vehiclesData.contains(vehicle)
                        }
                    }
                    return stateData.contains(state)
                }
            }
            
            // Additional filter
            let uid = FireManager.getUid()
            if self.segmentedControl.selectedSegmentIndex == 0 {
                self.orderList = self.orderList.filter { order in
                    if let bidderIDs = order.bidderIDs {
                        if order.vendorId != uid {
                            return !bidderIDs.contains(uid)
                        } else {
                            return true
                        }
                    } else {
                        return true // or handle the case when bidderIDs is nil
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.loading.dismiss()
            }
        })
    }
    
    func checkVerifyId(){
        let ref = FireConstants.usersRef.child(FireManager.getUid())
        
        // Observe for data changes in the Firebase database
        ref.observe(.value) { snapshot in
            if !snapshot.exists() {
                return
            }
            
            // Check if the "isIdVerified" field exists in the snapshot
            if let verifyId = snapshot.childSnapshot(forPath: "isIdVerified").value as? Bool {
                self.verifyIdStatus = verifyId
                print("verifyIdStatus  \(self.verifyIdStatus)")
            }
        }
    }

    
    func checkIfNetsAvailable(_ order: Order) {
        if order.status == "CREATED"{
            
            loading.show(text: "Please wait...".localized)
            let ref = FireConstants.usersRef.child(FireManager.getUid())
            ref.observeSingleEvent(of: .value) { snapshot in

                if !snapshot.exists() {
                    return
                }

                if let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int {
                    self.netbalance = nets
                    DispatchQueue.main.async {
                        self.loading.dismiss()
                        if self.netbalance > 2 {
                            self.showNetsChargingAlert(order)
                        } else {
                            self.showLowNetAlert()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.loading.dismiss()
                        if self.netbalance > 2 {
                            self.showNetsChargingAlert(order)
                        } else {
                            self.showLowNetAlert()
                        }
                    }
                }
            }
        }
    }

    func showNetsChargingAlert(_ order: Order) {
        let alert = UIAlertController(title: nil, message: "2 Nets will be charged for this Bid.\nDo you want to continue?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        }))
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Sure", style: .default, handler: { [weak alert] (_) in
            self.showAlert(order)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlert(_ order: Order) {
        let alert = UIAlertController(title: nil, message: "How much do you want to charge for this job", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = "\(order.price ?? 0)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           
        }))
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Sure", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            self.bidOnOrder(order, textField!.text!)
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func showLowNetAlert() {
        let alert = UIAlertController(title: nil, message: "Insufficient Nets to bid on this order.\nDo you want to add Net?", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           
        }))
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Sure", style: .default, handler: { [weak alert] (_) in
            self.walletBtnClicked()
            
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    @objc func walletBtnClicked() {
        let storyboard = UIStoryboard(name: "Payment", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PaymentViewController") as! PaymentViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    func showImageView(_ imageURL: String) {
        loading.show(text: "Please wait...".localized)
        let url = URL(string: imageURL)!
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
            if let data = data {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Order Image", message: "", preferredStyle: UIAlertController.Style.alert)
                    let image = UIImage(data: data)!
                    alert.addImage(image: image)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)) // show the alert self.present(alert, animated: true, completion: nil)
                    self?.loading.dismiss()
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        // Start Data Task
        dataTask.resume()
    }
    
    func bidOnOrder(_ order: Order,_ price: String) {
        loading.show(text: "Please wait...".localized)
        let bid = Bid.init(priceRequired: order.price, vendorName: order.vendorName, vendorId: order.vendorId, priceoffered: Int(price), accepted: false, timestamp: Double(Date().timeIntervalSince1970), netsUsed: order.netsRequired, netsRequired: order.netsRequired, orderId: order.orderId, bidderName: user.userName, userId: FireManager.getUid(), bidId: nil)

        FirebaseManager.sharedFirebaseManager.bidOnOrder(bid: bid) { error in
            if error != nil {
                DispatchQueue.main.async {
                    self.loading.dismiss()
                    self.showAlert(type: .error, message: "Something went wrong. Please try again")
                }
            } else {
                DispatchQueue.main.async {
                    self.getOrdersForDeliveryOperator()
                    self.loading.dismiss()
                    self.showAlert(type: .success, message: "Bid Completed")
                    
                    //bid push notification
                    pushNotificationCreateUserId(userId: bid.vendorId!, userName: "Biddings", message: "\(bid.bidderName!) bids on your request", type: Config.Type_Of_Bid)
                }
            }
        }
    }
    func addRateReview(){
        self.viewBlur.isHidden = true
        self.loading.show(text: "Please wait...".localized)
        
        let venRating = self.selectedOrder.vendorRating!
        let venReview = self.selectedOrder.vendorReview!
        let operatorReview = self.txtReview.text!
        let operatorRating = Float(self.score)
        
        FirebaseManager.sharedFirebaseManager.markOrderComplete(self.selectedOrder, venRating, venReview, operatorRating, operatorReview) { error in
            if error != nil {
                DispatchQueue.main.async {
                    self.loading.dismiss()
                    self.showAlert(type: .error, message: "Something went wrong. Please try again")
                }
            } else {
                DispatchQueue.main.async {
                    self.loading.dismiss()
                    self.showAlert(type: .success, message: "Thankyou for completing the Job.")
                }
            }
        }
    }
    
    //MARK: - Button Actions
    @IBAction func btnAddOrderAction(_ sender: Any) {
        let vendorOrderVC = AddVendorOrderViewController(nibName: "AddVendorOrderViewController", bundle: nil)
        vendorOrderVC.user = self.user
        self.navigationController?.pushViewController(vendorOrderVC, animated: true)
    }
    

    @IBAction func btnDismissAction(_ sender: Any) {
        self.viewBlur.isHidden = true
    }
    @IBAction func btnOKAction(_ sender: UIButton) {
        addRateReview()
    }
    
    @IBAction func btnCancelAction(_ sender: UIButton) {
        self.viewBlur.isHidden = true
    }
    
    @IBAction func segmentedIndexChanged(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            isCreated = false
            isAssignedToMeSelected = false
            isCompleted = false
        case 1:
            isCreated = false
            isAssignedToMeSelected = true
            isCompleted = false
        case 2:
            isCreated = true
            isAssignedToMeSelected = false
            isCompleted = false
        default:
            isCreated = false
            isAssignedToMeSelected = false
            isCompleted = false
        }
        self.getOrdersForDeliveryOperator()
    }
    
    
    
}

extension OperatorViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return orderList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
   
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let orders = orderList[indexPath.section]
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            if self.orderList[indexPath.section].status == FirebaseManager.sharedFirebaseManager.CREATED {
                
                
                if let cell = tableView.dequeueReusableCell(withIdentifier: "OperatorOrderCell") as? OperatorOrderCell {
                    cell.tag = indexPath.section
                    cell.configureCell(orderList[indexPath.section])
                    let bidderIDs = orders.bidderIDs
                    
                    if orders.vendorId == FireManager.getUid() {
                        cell.bidButton.setTitle("Check Bids", for: .normal)
                        cell.bidButton.isUserInteractionEnabled = true
                        cell.bidButton.alpha = 1
                    } else {
                        cell.bidButton.setTitle("BID", for: .normal)
                        cell.bidButton.isUserInteractionEnabled = true
                        cell.bidButton.alpha = 1
                    }
                    cell.bidButtonTapped = { [self] row in
                        if verifyIdStatus == true {
                            if orderList[indexPath.section].vendorId == FireManager.getUid() {
                                let orderDetailVC = OrderDetailViewController(nibName: "OrderDetailViewController", bundle: nil)
                                orderDetailVC.order = orderList[row]
                                navigationController?.pushViewController(orderDetailVC, animated: true)
                            } else {
                                checkIfNetsAvailable(orderList[row])
                            }
                        } else {
                            showAlert(type: .error, message: "Account not yet verified.")
                        }
                    }
                    cell.imageBtnTapped = { row in
                        if let image = self.orderList[row].image {
                            self.showImageView(image)
                        } else {
                            self.showAlert(type: .info, message: "Image not available")
                        }
                    }
                    return cell
                }
            }
        case 1:
            if self.orderList[indexPath.section].status == FirebaseManager.sharedFirebaseManager.ASSIGNED {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "AssignedBidCell") as? AssignedBidCell {
                    cell.tag = indexPath.section
                    cell.configureCell(orderList[indexPath.section])
                    
                    cell.bidButtonTapped = { row in
                        self.loading.show(text: "Please wait...".localized)
                        self.chats = RealmHelper.getInstance(appRealm).getChats().filter("chatId == '\(self.orderList[indexPath.section].orderId!)'")
                        
                        if self.chats.count != 0 {
                            let chat = self.chats[0]
                            let user = chat.user
                            self.loading.dismiss()
                            self.goToChatVC(user: user!)
                        }else{
                            self.loading.dismiss()
                        }
                    }
        
                    
                    cell.checkRouteTapped = { row in
                        let realmHelper = RealmHelper.getInstance(appRealm)
                        guard let user = realmHelper.getUser(uid: orders.vendorId ?? "") else {
                            return
                        }
                        if !user.phone.isEmpty {
                            self.call(phoneNumber: user.phone)
                        }
                    }
                    
                    cell.completeMarkBtn = { row in
                        self.showJobMarkingAlert(self.orderList[indexPath.section])
//                        self.AddRateReviewVendor(self.orderList[indexPath.section])
                    }
                    cell.imageBtnTapped = { row in
                        if let image = self.orderList[row].image {
                            self.showImageView(image)
                        } else {
                            self.showAlert(type: .info, message: "Image not available")
                        }
                    }
                    return cell
                }
            }
        case 2:
            if self.orderList[indexPath.section].status == FirebaseManager.sharedFirebaseManager.CREATED {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "OperatorOrderCell") as? OperatorOrderCell {
                    cell.tag = indexPath.section
                    cell.configureCell(orderList[indexPath.section])
//                    let bidderIDs = orders.bidderIDs
                    
                    if let bidderIDs = orders.bidderIDs {
                        if ((bidderIDs.contains(where: { $0 == FireManager.getUid() })) != nil) {
                            cell.bidButton.setTitle("BIDED", for: .normal)
                            cell.bidButton.isUserInteractionEnabled = false
                            cell.bidButton.alpha = 0.5
                        }
                    }
                    
                    cell.imageBtnTapped = { row in
                        if let image = self.orderList[row].image {
                            self.showImageView(image)
                        } else {
                            self.showAlert(type: .info, message: "Image not available")
                        }
                    }
                    return cell
                }
            }
            
        default:
            return UITableViewCell()
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func goToChatVC(user: User) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.initialize(user: user)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func showJobMarkingAlert(_ order: Order) {
        let alert = UIAlertController(title: nil, message: "Please confirm if the job assigned to you is completed?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
           
        }))
        alert.addAction(UIAlertAction(title: "Sure", style: .default, handler: { [weak alert] (_) in
            self.viewBlur.isHidden = false
            self.viewStarRate.isHidden = false
            self.lblParcelName.text = order.orderDiscription
            self.txtReview.text = ""
            
            let starView = StarRateView(frame: CGRect(x: 0, y: 5, width: 125, height: 20),totalStarCount: 5, currentStarCount: 0, starSpace: 10)
            starView.show { (score) in
                self.score = score
            }
            self.selectedOrder = order
            self.viewStarRate.addSubview(starView)
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func call(phoneNumber:String) {
        let cleanPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        let urlString:String = "tel://\(cleanPhoneNumber)"
        if let phoneCallURL = URL(string: urlString) {
            if (UIApplication.shared.canOpenURL(phoneCallURL)) {
                UIApplication.shared.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    
    func AddRateReviewVendor(_ order: Order) {
        self.viewStarRate.isHidden = false
        self.lblParcelName.text = order.orderDiscription
        self.txtReview.text = ""
        self.viewBlur.isHidden = false
        
        let starView = StarRateView(frame: CGRect(x: 0, y: 5, width: 125, height: 20),totalStarCount: 5, currentStarCount: 0, starSpace: 10)
        starView.show { (score) in
            self.score = score
        }
        self.selectedOrder = order
        self.viewStarRate.addSubview(starView)
    }
    
    
}
