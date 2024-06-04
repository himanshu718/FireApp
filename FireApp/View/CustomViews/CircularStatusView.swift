//
//  CircularStatusView.swift
//  FireApp
//
//  Created by Devlomi on 11/5/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class CircularStatusView: UIView {

    var portionWidth: CGFloat = 1.8
    var portionSpacing: CGFloat = 5
    
    var portionColor = UIColor.lightGray {
        didSet {

            portionsToUpdateDict.removeAll()
            setNeedsDisplay()
        }
    }

    var portionsCount = 1 {
        didSet {
            setNeedsDisplay()
        }
    }



    private let START_DEGREE: CGFloat = -90

    private var portionsToUpdateDict = [Int: UIColor]()



    

    override func draw(_ rect: CGRect) {

        layer.backgroundColor = UIColor.clear.cgColor

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(center.x, center.y) - portionWidth



        let degree: CGFloat = CGFloat(360 / portionsCount)


        for i in 0...portionsCount - 1 {

            

            getColorByIndex(i).set()


            let startAngle = radians(of: START_DEGREE + (degree * CGFloat(i)) + getSpacing())


            let endAngle = radians(of: START_DEGREE + (degree * CGFloat((i + 1))) - getSpacing())


            let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

            circlePath.lineWidth = portionWidth
            circlePath.lineCapStyle = .round

            circlePath.stroke()
            
            

        }




    }



    public func setPortionColorForIndex(index: Int, color: UIColor) {

        portionsToUpdateDict[index] = color

    }
    
  

    private func radians(of degrees: CGFloat) -> CGFloat {
        return degrees / 180 * .pi
    }

    private func getProgressAngle(percent: CGFloat) -> CGFloat {
        return percent / 100 * 360
    }
    private func getSpacing() -> CGFloat {
        return portionsCount == 1 ? 0 : portionSpacing
    }




    private func getColorByIndex(_ index: Int) -> UIColor {
        if let color = portionsToUpdateDict[index] {
            return color
        }
        return portionColor
    }

}


