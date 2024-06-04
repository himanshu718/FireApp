//
//  OrdersViewCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 19/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class OrdersViewCell: UITableViewCell {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var orderDetail: UILabel!
    @IBOutlet weak var vendorName: UILabel!
    @IBOutlet weak var pickupLocation: UILabel!
    @IBOutlet weak var deliveryLocation: UILabel!
    @IBOutlet weak var priceOffered: UILabel!
    @IBOutlet weak var courierDetails: UILabel!
    @IBOutlet weak var pointsRequires: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainView.layer.borderColor = UIColor.black.cgColor
        mainView.layer.borderWidth = 1.0
        mainView.layer.cornerRadius = 8
        mainView.clipsToBounds = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func bidButtonTapped(_ sender: Any) {
        
    }
}
