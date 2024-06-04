//
//  GradientView.swift
//  FireApp
//
//  Created by Devlomi on 7/13/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//
import UIKit


class GradientView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        setColors()
    }

    let gradient: CAGradientLayer = CAGradientLayer()

    fileprivate func setColors() {


        let startColor = UIColor.black.withAlphaComponent(0.2).cgColor
        let centerColor = UIColor.black.withAlphaComponent(0.1).cgColor

        let endColor = UIColor.black.withAlphaComponent(0).cgColor

        gradient.colors = [endColor, centerColor, startColor]
        gradient.locations = [0.0, 0.3, 1.0]

        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: self.frame.size.height)

        self.layer.insertSublayer(gradient, at: 0)

    }

}

