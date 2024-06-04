//
//  AssignedVC.swift
//  FireApp
//
//  Created by iMac on 31/10/23.
//  Copyright © 2023 Devlomi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import RxSwift
import RealmSwift

class AssignedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var orderList: [Order] = []
    var user: User!
    let loading = LoadingViewController()
    var disposeBag = DisposeBag()
    var chats: Results<Chat>!
    
    //MARK: - Outlets
    @IBOutlet weak var tblAssignedList: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblAssignedList.delegate = self
        tblAssignedList.dataSource = self
        tblAssignedList.register(UINib(nibName: "AssignedOrderCell", bundle: nil), forCellReuseIdentifier: "AssignedOrderCell")
        getVendorOrderList()
        
        user = RealmHelper.getInstance(appRealm).getUser(uid: FireManager.getUid())
        
    }
    
    //MARK: - Custom Functions
    func getVendorOrderList() {
        self.orderList = []
        self.orderList.removeAll()
        
        loading.show(text: "Please wait...".localized)
        FirebaseManager.sharedFirebaseManager.getVendorOrders(true, false, completion:{ (documents, error) in
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
                self.tblAssignedList.reloadData()
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
    func goToChatVC(user: User) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.getResourcesBundle())
        let vc = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.initialize(user: user)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Tableview methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.orderList[indexPath.row].status == FirebaseManager.sharedFirebaseManager.ASSIGNED{
            if let cell = tableView.dequeueReusableCell(withIdentifier: "AssignedOrderCell") as? AssignedOrderCell{
                cell.chatBtn.tag = indexPath.section
                cell.configureCell(orderList[indexPath.row])
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
        return UITableViewCell()
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
}
