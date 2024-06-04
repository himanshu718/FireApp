//
//  VendorOrderCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 12/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class VendorOrderCell: UITableViewCell {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var orderDetailsLabel: UILabel!
    @IBOutlet weak var pickUpLocationLabel: UILabel!
    @IBOutlet weak var deliveryLocationLabel: UILabel!
    @IBOutlet weak var priceOfferedLabel: UILabel!
    @IBOutlet weak var numberOfBidsReceived: UILabel!

    @IBOutlet weak var sizeOfBids: UILabel!
    
    @IBOutlet weak var checkButton: UIButton!
    
    var urlStr: String?
    
    var buttonTapped : ((Int) -> Void)? = nil
    var imageBtnTapped: ((Int) -> Void)? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
        
    }
    
    @IBAction func viewImageBtnTapped(_ sender: Any) {
        guard let image = urlStr else { return }
        if let buttonTapped = self.imageBtnTapped {
            buttonTapped(self.tag)
        }
    }
    
    @IBAction func checkbtnAction(sender: UIButton) {
        if let buttonTapped = self.buttonTapped {
            buttonTapped(sender.tag)
        }
    }
}
