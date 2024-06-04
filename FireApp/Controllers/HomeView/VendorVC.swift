//
//  VendorVC.swift
//  FireApp
//
//  Created by iMac on 24/07/23.
//  Copyright © 2023 Devlomi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import RxSwift
import DropDown
import RealmSwift

enum userType {
    case Vendor
    case Operator
}

class VendorVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var orderList: [Order] = []
    var user: User!
    
    let loading = LoadingViewController()
    let dropDown = DropDown()
    var disposeBag = DisposeBag()
    
    
    var isAssigned = false
    var isCompleted = false
    
    
    var score = CGFloat()
    var selectedOrder: Order!
    
    //MARK: - Outlets
    @IBOutlet weak var segmentController: UISegmentedControl!
    @IBOutlet weak var tblOrderLists: UITableView!
    
    @IBOutlet weak var viewBlur: UIView!
    @IBOutlet weak var lblOrdername: UILabel!
    @IBOutlet weak var viewStarRate: UIView!
    @IBOutlet weak var txtAddReview: UITextField!
    @IBOutlet weak var viewBoard: UIView!
    
    //MARK: - Viewcycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewBlur.isHidden =  true
        viewBoard.layer.cornerRadius = 8
        viewBoard.layer.masksToBounds = true
        
        getVendorOrderList()
        
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
        tblOrderLists.delegate = self
        tblOrderLists.dataSource = self
        tblOrderLists.registerCellNib(cellClass: VendorOrderCell.self)
        tblOrderLists.registerCellNib(cellClass: AssignedOrderCell.self)
        tblOrderLists.registerCellNib(cellClass: CompletedOrderCell.self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(hexString: "#2196f5")
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    
    //MARK: - Button Actions
    @IBAction func btnAddOrderAction(_ sender: UIButton) {
        let vendorOrderVC = AddVendorOrderViewController(nibName: "AddVendorOrderViewController", bundle: nil)
        vendorOrderVC.user = self.user
        self.navigationController?.pushViewController(vendorOrderVC, animated: true)
    }
    func addRateReview(){
        self.viewBlur.isHidden = true
        self.loading.show(text: "Please wait...".localized)
        
        let venRating = Float(self.score)
        let venReview = self.txtAddReview.text!
        let operatorReview = self.selectedOrder.operatorReview!
        let operatorRating = self.selectedOrder.operatorRating!
        
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
    
   
    
    @IBAction func btnDismissAction(_ sender: UIButton) {
        self.viewBlur.isHidden = true
    }
    @IBAction func btnOkAction(_ sender: Any) {
        addRateReview()
    }
    @IBAction func btncancelAction(_ sender: Any) {
        self.viewBlur.isHidden = true
    }
    
    @IBAction func segmentContollerAction(_ sender: Any) {
        
        switch segmentController.selectedSegmentIndex {
        case 0:
            isAssigned = false
            isCompleted = false
        case 1:
            isAssigned = true
            isCompleted = false
        case 2:
            isAssigned = false
            isCompleted = true
        default:
            isAssigned = false
            isCompleted = false
        }
        self.getVendorOrderList()
    }
    
    func addWalletButton() {
        let button: UIButton = UIButton(type: UIButton.ButtonType.custom)
        //set image for button
        button.setImage(UIImage(named: "wallet"), for: .normal)
        //add function for button
        button.addTarget(self, action: #selector(walletBtnClicked), for: .touchUpInside)
        //set frame
        button.frame = CGRect(x: 0, y: 0, width: 53, height: 31)
        
        let barButton = UIBarButtonItem(customView: button)
        //assign button to navigationbar
        tabBarController?.navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func walletBtnClicked() {
        let storyboard = UIStoryboard(name: "Payment", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PaymentViewController") as! PaymentViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    
    func getVendorOrderList() {
        self.orderList = []
        
        loading.show(text: "Please wait...".localized)
        FirebaseManager.sharedFirebaseManager.getVendorOrders(isAssigned, isCompleted, completion:{ (documents, error) in
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

            DispatchQueue.main.async {
                self.tblOrderLists.reloadData()
                self.loading.dismiss()
            }
        })
    }
    
    func AddRateReviewVendor(_ order: Order) {
        self.viewStarRate.isHidden = false
        self.lblOrdername.text = order.orderDiscription
        self.txtAddReview.text = ""
        self.viewBlur.isHidden = false
        
        let starView = StarRateView(frame: CGRect(x: 0, y: 5, width: 125, height: 20),totalStarCount: 5, currentStarCount: 0, starSpace: 10)
        starView.show { (score) in
            self.score = score
        }
        self.selectedOrder = order
        self.viewStarRate.addSubview(starView)
    }
    
    //MARK: - Tableview methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return orderList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    var chats: Results<Chat>!
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let order = orderList[indexPath.section]
        switch segmentController.selectedSegmentIndex {
        case 0:
            if self.orderList[indexPath.section].status == FirebaseManager.sharedFirebaseManager.CREATED{
                if let cell = tableView.dequeueReusableCell(withIdentifier: "VendorOrderCell") as? VendorOrderCell {
                    cell.checkButton.tag = indexPath.section
                    cell.configureCell(orderList[indexPath.section])
                    cell.buttonTapped = { row in
                        let orderDetailVC = OrderDetailViewController(nibName: "OrderDetailViewController", bundle: nil)
                        orderDetailVC.order = self.orderList[row]
                        self.navigationController?.pushViewController(orderDetailVC, animated: true)
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
            if self.orderList[indexPath.section].status == FirebaseManager.sharedFirebaseManager.ASSIGNED{
                if let cell = tableView.dequeueReusableCell(withIdentifier: "AssignedOrderCell") as? AssignedOrderCell {
                    cell.chatBtn.tag = indexPath.section
                    cell.configureCell(orderList[indexPath.section])
                    cell.buttonTapped = { row in
                        self.loading.show(text: "Please wait...".localized)
                        print(self.orderList[indexPath.section].orderId!)
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
                    
                    cell.imageBtnTapped = { row in
                        let realmHelper = RealmHelper.getInstance(appRealm)
                        guard let user = realmHelper.getUser(uid: self.orderList[indexPath.row].assignedUserId ?? "") else {
                            return
                        }
                        if !user.phone.isEmpty {
                            self.call(phoneNumber: user.phone)
                        }
                    }
                    return cell
                }
            }
        case 2:
            if self.orderList[indexPath.section].status == FirebaseManager.sharedFirebaseManager.COMPLETED{
                if let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedOrderCell") as? CompletedOrderCell {
                    cell.checkButton.tag = indexPath.section
                    cell.configureCell(orderList[indexPath.section])
                    
                    cell.checkButtonTapped = { row in
                        if cell.checkButton.title(for: .normal) == "Add Rating"{
                            self.AddRateReviewVendor(order)
                        }
                    }
                    
                    cell.lblRates.isHidden = true
                    cell.viewStarRate.isHidden = true
                    cell.lblReview.isHidden = true
                    cell.lblOperatorReview.isHidden = true
                    
                    if order.operatorRating != 0.0 || order.operatorReview != ""{
                        cell.lblRates.isHidden = false
                        cell.viewStarRate.isHidden = false
                        cell.lblReview.isHidden = false
                        cell.lblOperatorReview.isHidden = false
                        
                        let rate = CGFloat(order.operatorRating!)
                        let starView = StarRateView(frame: CGRect(x: 0, y: 0, width: 125, height: 20),totalStarCount: 5, currentStarCount: rate, starSpace: 5)
                        cell.viewStarRate.addSubview(starView)
                        cell.lblOperatorReview.text = order.operatorReview
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func goToChatListVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "chatsListVC") as! ChatsListVC
        navigationController?.pushViewController(vc, animated: true)
    }
    func goToChatVC(user: User) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.initialize(user: user)
        navigationController?.pushViewController(vc, animated: true)
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
    
    func goToSettingsVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "settingsVC") as! SettingsVC
        navigationController?.pushViewController(vc, animated: true)
    }
}

