//
//  ItemCollectionViewCell.swift
//  FireApp
//
//  Created by Kartik Gupta on 09/11/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit

class ItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let view = UIView(frame: bounds)
        view.layer.cornerRadius = 20.0
        view.backgroundColor = UIColor.systemGray
        self.backgroundView = view
        
        let coloredView = UIView(frame: bounds)
        coloredView.backgroundColor = UIColor.systemBlue
        coloredView.layer.cornerRadius = 20.0
        self.selectedBackgroundView = coloredView
        // Initialization code
    }

}
