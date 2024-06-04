//
//  LimitedTabPageViewController.swift
//  TabPageViewController
//
//  Created by Tomoya Hayakawa on 2017/08/05.
//
//

import UIKit
import TabPageViewController

@available(iOS 13.0, *)
class VendorTabPageViewController: TabPageViewController {

    override init() {
        super.init()
        let vc1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VendorVC")
        let vc2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatsListVC")
        let vc3 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CallsVC")
        tabItems = [(vc1, "MY JOBS"), (vc2, "CHATS"), (vc3, "CALLS")]
        
        option.tabWidth = view.frame.width / CGFloat(tabItems.count)
        option.hidesTopViewOnSwipeType = .tabBar
        
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
