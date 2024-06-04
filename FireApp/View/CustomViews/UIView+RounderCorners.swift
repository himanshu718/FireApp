//
//  UIView+RounderCorners.swift
//  FireApp
//
//  Created by Devlomi on 9/16/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

@IBDesignable class UIViewWithRoundedCorners: UIView {
    @IBInspectable var fullRoundedCorners: Bool = true

    @IBInspectable var radius: Float = 0
    
    @IBInspectable var topLeft: Bool = false
    @IBInspectable var topRight: Bool = false
    @IBInspectable var bottomLeft: Bool = false
    @IBInspectable var bottomRight: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }


    fileprivate func setup() {
        if fullRoundedCorners {
            layer.cornerRadius = CGFloat(radius)
        } else {
            
            var roundingCorners =  UIRectCorner()
            
            if topLeft{
                roundingCorners.insert(.topLeft)
            }
            if topRight{
                roundingCorners.insert(.topRight)
            }
            if bottomLeft{
                roundingCorners.insert(.bottomLeft)
            }
            if bottomRight{
                roundingCorners.insert(.bottomRight)
            }
            
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: CGFloat(radius), height: CGFloat(radius)))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }

}
