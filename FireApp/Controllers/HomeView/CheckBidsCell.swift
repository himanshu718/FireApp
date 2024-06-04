//
//  CheckBidsCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 17/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class CheckBidsCell: UITableViewCell {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var OperatorName: UILabel!
    @IBOutlet weak var priceOffered: UILabel!
    @IBOutlet weak var assignButton: UIButton!
    
    var buttonTapped : ((Int) -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        mainView.layer.borderColor = UIColor.black.cgColor
//        mainView.layer.borderWidth = 1.0
//        mainView.layer.cornerRadius = 8
//        mainView.clipsToBounds = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(_ bid: Bid) {
        self.OperatorName.text = bid.bidderName
        self.priceOffered.text = "\(bid.priceoffered!)"
    }
    
    @IBAction func assignbtnAction(sender: UIButton) {
        if let buttonTapped = self.buttonTapped {
            buttonTapped(sender.tag)
        }
    }
    
}
