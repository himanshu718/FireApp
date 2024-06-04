//
//  CircleView.swift
//  FireApp
//
//  Created by Devlomi on 7/4/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
class CircleView:UIView{
    
    var color:UIColor = UIColor.red
    
    override func draw(_ rect: CGRect) {
        self.backgroundColor = .clear
        
        let path = UIBezierPath(ovalIn: rect)
        color.setFill()
        path.fill()
    }

}
