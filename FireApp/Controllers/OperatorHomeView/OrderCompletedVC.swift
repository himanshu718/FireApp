//
//  OrderCompletedVC.swift
//  FireApp
//
//  Created by iMac on 31/10/23.
//  Copyright © 2023 Devlomi. All rights reserved.
//

import UIKit

class OrderCompletedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var orderList: [Order] = []
    var user: User!
    let loading = LoadingViewController()
    
    var score = CGFloat()
    var selectedOrder: Order!
    
    @IBOutlet weak var tblCompletedOrderList: UITableView!
    @IBOutlet weak var viewBlur: UIView!
    @IBOutlet weak var viewStarRate: UIView!
    @IBOutlet weak var txtReview: UITextField!
    @IBOutlet weak var lblParcelName: UILabel!
    @IBOutlet weak var viewBoard: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tblCompletedOrderList.delegate = self
        tblCompletedOrderList.dataSource = self
        tblCompletedOrderList.register(UINib(nibName: "MyBidCell", bundle: nil), forCellReuseIdentifier: "MyBidCell")
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
        viewBlur.isHidden =  true
        viewBoard.layer.cornerRadius = 8
        viewBoard.layer.masksToBounds = true
        
        getOrdersForDeliveryOperator()
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.viewBlur.isHidden = true
    }
    @IBAction func btnOkAction(_ sender: Any) {
        addRateReview()
    }
    @IBAction func btnCancelAction(_ sender: Any) {
        self.viewBlur.isHidden = true
    }
    
    //MARK: - Custom Functions
    func getOrdersForDeliveryOperator() {
        self.orderList = []
        
        loading.show(text: "Please wait...".localized)
        FirebaseManager.sharedFirebaseManager.getOrdersForDeliveryOperator(false, false, true, completion: { (documents, error) in
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
                if item.vendorId == self.user.uid{
                    return true
                }else {
                    guard let state = item.state else{
                        if vehiclesData.contains("Anyone"){
                            return true
                        }else{
                            guard let vehicle = item.vehicleType else{
                                return true
                            }
                            return vehiclesData.contains(vehicle)
                        }
                    }
                    return stateData.contains(state)
                }
            }
            
            DispatchQueue.main.async {
                self.tblCompletedOrderList.reloadData()
                self.loading.dismiss()
            }
        })
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
    
    //MARK: - Tables methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let orders = orderList[indexPath.row]
        if self.orderList[indexPath.row].status == FirebaseManager.sharedFirebaseManager.COMPLETED{
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MyBidCell") as? MyBidCell{
                cell.tag = indexPath.section
                cell.configureCell(orderList[indexPath.row])
                cell.completedButtonTapped = { row in
                    if cell.btnCompleted.title(for: .normal) == "Add Rating"{
                        self.AddRateReviewVendor(orders)
                    }
                }
                
                cell.lblRates.isHidden = true
                cell.viewStarRate.isHidden = true
                cell.lblReview.isHidden = true
                cell.lblVendorReview.isHidden = true

                if orders.vendorRating != 0.0 || orders.vendorReview != ""{
                    cell.lblRates.isHidden = false
                    cell.viewStarRate.isHidden = false
                    cell.lblReview.isHidden = false
                    cell.lblVendorReview.isHidden = false
                    
                    let rate = CGFloat(orders.vendorRating!)
                    let starView = StarRateView(frame: CGRect(x: 0, y: 0, width: 125, height: 20),totalStarCount: 5, currentStarCount: rate, starSpace: 5)
                    cell.viewStarRate.addSubview(starView)
                    cell.lblVendorReview.text = orders.vendorReview
                }
                
                cell.checkRouteTapped = { row in
                    //                    let routeVC = RouteViewController(nibName: "RouteViewController", bundle: nil)
                    //                    routeVC.order = self.orderList[row]
                    //                    self.navigationController?.pushViewController(routeVC, animated: true)
                    self.showAlert(type: .info, message: "Route functionality not available currently")
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
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
