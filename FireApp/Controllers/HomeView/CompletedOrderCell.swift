//
//  VendorOrderCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 12/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class CompletedOrderCell: UITableViewCell {

    //MARK: - outlets
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var orderDetailsLabel: UILabel!
    @IBOutlet weak var pickUpLocationLabel: UILabel!
    @IBOutlet weak var deliveryLocationLabel: UILabel!
    @IBOutlet weak var priceOfferedLabel: UILabel!
    @IBOutlet weak var numberOfBidsReceived: UILabel!

    @IBOutlet weak var sizeOfBids: UILabel!
    
    @IBOutlet weak var checkButton: UIButton!
    
    @IBOutlet weak var lblRates: UILabel!
    @IBOutlet weak var viewStarRate: UIView!
    @IBOutlet weak var lblReview: UILabel!
    @IBOutlet weak var lblOperatorReview: UILabel!
    
    @IBOutlet weak var btnCheckTopAnchor: NSLayoutConstraint!
    
    var urlStr: String?
    var checkButtonTapped : ((Int) -> Void)? = nil
    var imageBtnTapped: ((Int) -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
        
        self.numberOfBidsReceived.text = "\(order.bidderIDs?.count ?? 0)"
        self.sizeOfBids.text = "\(order.size?.count ?? 0)"
        urlStr = order.image
        
        checkButton.isHidden = hideButton
    
        
        
        if order.vendorRating == 0.0 || order.vendorReview == ""{
            checkButton.setTitle("Add Rating", for: .normal)
            if order.operatorRating == 0.0 && order.operatorReview == "" {
                btnCheckTopAnchor.constant = -60
            } else {
                btnCheckTopAnchor.constant = 0
            }
        } else{
            checkButton.setTitle("Completed", for: .normal)
            if order.operatorRating == 0.0 && order.operatorReview == "" {
                btnCheckTopAnchor.constant = -60
            } else {
                btnCheckTopAnchor.constant = 0
            }
            
        }
    }
    
//    @IBAction func viewImageBtnTapped(_ sender: Any) {
//        guard let image = urlStr else { return }
//        if let buttonTapped = self.imageBtnTapped {
//            buttonTapped(self.tag)
//        }
//    }
//
    @IBAction func checkbtnAction(sender: UIButton) {
        if let buttonTapped = self.checkButtonTapped {
            buttonTapped(sender.tag)
        }
    }
}
