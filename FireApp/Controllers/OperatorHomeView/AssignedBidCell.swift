//
//  OperatorOrderCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 03/12/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class AssignedBidCell: UITableViewCell {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var orderDetailsLabel: UILabel!
    @IBOutlet weak var vendorNameLabel: UILabel!
    @IBOutlet weak var pickUpLocationLabel: UILabel!
    @IBOutlet weak var deliveryLocationLabel: UILabel!
    @IBOutlet weak var priceOfferedLabel: UILabel!
    @IBOutlet weak var pointsRequiredLabel: UILabel!
    @IBOutlet weak var bidButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    var completeMarkBtn: ((Int) -> Void)? = nil
    var bidButtonTapped: ((Int) -> Void)? = nil
    var checkRouteTapped: ((Int) -> Void)? = nil
    var imageBtnTapped: ((Int) -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(_ order: Order,_ hideButton: Bool = false) {
        if var timestamp = order.timestamp {
            timestamp = changeTimeStampFormate(Time_Stamp: timestamp)
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium//Set time style
            dateFormatter.dateStyle = .medium //Set date style
            self.dateLabel.text = dateFormatter.string(from: date)
        }
        self.orderDetailsLabel.text = order.orderDiscription
        self.pickUpLocationLabel.text = order.pickup
        self.deliveryLocationLabel.text = order.delivery
        if let price = order.price {
            self.priceOfferedLabel.text = "₦\(price)"
        }
        
        if let netRequired = order.netsRequired {
            self.pointsRequiredLabel.text = "\(netRequired)"
        }
        bidButton.isHidden = hideButton
    }
    
    @IBAction func viewImagebtnAction(sender: UIButton) {
        if let buttonTapped = self.imageBtnTapped {
            buttonTapped(self.tag)
        }
    }
    
    @IBAction func bidButtonAction(sender: UIButton) {
        if let buttonTapped = self.bidButtonTapped {
            buttonTapped(self.tag)
        }
    }
    
    @IBAction func checkOnMapButtonAction(sender: UIButton) {
        if let buttonTapped = self.checkRouteTapped {
            buttonTapped(self.tag)
        }
    }
    
    @IBAction func completeMarkBtn(sender: UIButton) {
        if let buttonTapped = self.completeMarkBtn {
            buttonTapped(self.tag)
        }
    }
}
