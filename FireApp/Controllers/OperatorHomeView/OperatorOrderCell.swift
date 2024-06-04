//
//  OperatorOrderCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 03/12/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class OperatorOrderCell: UITableViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var orderDetailsLabel: UILabel!
    @IBOutlet weak var vendorNameLabel: UILabel!
    @IBOutlet weak var pickUpLocationLabel: UILabel!
    @IBOutlet weak var deliveryLocationLabel: UILabel!
    @IBOutlet weak var priceOfferedLabel: UILabel!
    @IBOutlet weak var pointsRequiredLabel: UILabel!
    @IBOutlet weak var bidButton: UIButton!
    @IBOutlet weak var bidsLabel: UILabel!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var imageBtnView: UIView!
    @IBOutlet weak var sizeLblView: UIView!
    @IBOutlet weak var venderLbl: UILabel!
    
    @IBOutlet weak var lblPickup: UILabel!
    @IBOutlet weak var lblPickupTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var lblVendorNameTopAnchor: NSLayoutConstraint!
    
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
        
        if order.vendorId == FireManager.getUid(){
            bidsLabel.text = "Bids Received"
            self.pointsRequiredLabel.text = "\(order.bidderIDs?.count ?? 0)"
            sizeLabel.text = "\(order.size?.count ?? 0)"
            imageBtnView.isHidden = true
            sizeLblView.isHidden = false
            
            venderLbl.isHidden = true
            vendorNameLabel.isHidden = true
  
            lblPickupTopAnchor.constant = -42
        } else {
            
            bidsLabel.text = "Nets Required"
            imageBtnView.isHidden = false
            sizeLblView.isHidden = true
            
            venderLbl.isHidden = false
            vendorNameLabel.isHidden = false
            vendorNameLabel.text = order.vendorName
                 
            lblVendorNameTopAnchor.constant = 12
            lblPickupTopAnchor.constant = 12

            if let netRequired = order.netsRequired {
                self.pointsRequiredLabel.text = "\(netRequired)"
            }
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
}
