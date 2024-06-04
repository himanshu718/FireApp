//
//  TextVCViewController.swift
//  FireApp
//
//  Created by Devlomi on 1/26/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import GrowingTextView

class TextVCViewController: UIViewController {
    
    @IBOutlet weak var tblView: UITableView!

    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
}
