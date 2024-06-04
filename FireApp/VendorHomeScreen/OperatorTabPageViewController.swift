//
//  OperatorTabPageViewController.swift
//  FireApp
//
//  Created by iMac on 31/10/23.
//  Copyright © 2023 Devlomi. All rights reserved.
//

import UIKit
import TabPageViewController

@available(iOS 13.0, *)
class OperatorTabPageViewController: TabPageViewController {

    override init() {
        super.init()
        let vc1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OperatorViewController")
        let vc2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AssignedVC")
        
        let vc3 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrderCompletedVC") 
        tabItems = [(vc1, "ORDERS"), (vc2, "ASSIGNED"), (vc3, "COMPLETED")]
        
        option.tabWidth = view.frame.width / CGFloat(tabItems.count)
        option.hidesTopViewOnSwipeType = .tabBar
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
