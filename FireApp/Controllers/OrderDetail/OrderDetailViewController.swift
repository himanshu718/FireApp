//
//  OrderDetailViewController.swift
//  FireApp
//
//  Created by Kartik Gupta on 17/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class OrderDetailViewController: UITableViewController {
    
    var order: Order!
    
    var bids = [Bid]()
    
    let loading = LoadingViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let view = UIView(frame: CGRect(x: 0, y: -100, width: UIScreen.main.bounds.width, height: 60))
        view.backgroundColor = .init(hexString: "2196F5")
        self.view.addSubview(view)
        
        title = Strings.orderDetail
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.registerCellNib(cellClass: VendorOrderCell.self)
        tableView.registerCellNib(cellClass: CheckBidsCell.self)
        getBidsOnOrder()
        setNavbar()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(hexString: "#2196f5")
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func getBidsOnOrder() {
        loading.show(text: "Please wait...".localized)
        
        FirebaseManager.sharedFirebaseManager.getBidsOnOrder(order.orderId ?? "", completion: { (documents, error) in
            self.bids = []
            if documents?.count ?? 0 > 0 {
                for document in documents! {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document, options: .prettyPrinted)
                        let bid = try Bid.init(data: data)
                        self.bids.append(bid)
                    } catch {
                        print("JSONSerialization error:", error)
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.loading.dismiss()
            }
        })
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
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + bids.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "VendorOrderCell", for: indexPath) as? VendorOrderCell {
                cell.configureCell(order, true)
                cell.imageBtnTapped = { row in
                    if let image = self.order.image {
                        self.showImageView(image)
                    } else {
                        self.showAlert(type: .info, message: "Image not available")
                    }
                }
                return cell
            }
        default:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CheckBidsCell", for: indexPath) as? CheckBidsCell {
                cell.assignButton.tag = indexPath.section - 1
                cell.configureCell(bids[indexPath.section - 1])
                cell.buttonTapped = { row in
                    self.loading.show(text: "Order Assigning...".localized)
                    FirebaseManager.sharedFirebaseManager.assignOrder(order: self.order, bid: self.bids[row]) { error in
                        self.loading.dismiss()
                        if error == nil {
                            let biderID = self.bids[row].userId
                            
                            if let bider : User = RealmHelper.getInstance(appRealm).getUser(uid: biderID!){
                                self.presentAlertWith(title: "Alert", message: "Bid Assigned Successfully", options: "ok") { (option) in
                                    switch(option) {
                                    case 0:
                                        GroupManager.createNewGroupForSpecificOrder(groupId: self.order.orderId!, groupTitle: self.order.orderDiscription!, users: []).subscribe(onSuccess: { (groupUser) in
                                            
                                            print("GRoup User for addParticipants \(groupUser)")
                                            
                                            GroupManager.addParticipants(groupUser: groupUser, users: [bider]).subscribe {
                                                print("single user create")
                                                
                                                pushNotificationCreateUserId(userId: bider.uid, userName: "Congrats! 🎉",    message: "You have been assigned.", type: Config.Type_Of_AssignOrder)
                                                
                                                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
                                                let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                                                vc.initialize(user: groupUser)
                                                vc.isHomePush = true
                                                self.navigationController?.pushViewController(vc, animated: true)
                                            }
                                            
                                        }, onError: { (error) in
                                                print(error)
                                        })
                                        break
                                    default:
                                        break
                                    }
                                }
                            }else{
                                self.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            self.showAlert(type: .error, message: "Something went wrong. Please try again.")
                        }
                    }
                }
                return cell
            }
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
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    self?.loading.dismiss()
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
        dataTask.resume()
    }
    
}
