//
//  StatusSeenByVC.swift
//  FireApp
//
//  Created by Devlomi on 3/17/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
import BottomPopup

class StatusSeenByVC: BottomPopupViewController {
    var statusSeenByArray = [StatusSeenBy](){
        didSet{
            if tableView != nil{
            tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var tableView:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
    
        
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}

extension StatusSeenByVC:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statusSeenByArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "statusSeenByCell") as? StatusSeenByCell{
            let statusSeenBy = statusSeenByArray[indexPath.row]
            cell.bind(statusSeenBy: statusSeenBy)
            return cell
        }
        
        return UITableViewCell()
    }
    
    
}
