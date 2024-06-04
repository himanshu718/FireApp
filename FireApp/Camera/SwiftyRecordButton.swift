//
//  SwiftyRecordButton.swift
//  FireApp
//
//  Created by Devlomi on 6/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//
import SwiftyCam

class SwiftyRecordButton: SwiftyCamButton {
    
    private var circleBorder: CALayer!
    private var innerCircle: UIView!
    let percent = 50.0

    let progressShape = CAShapeLayer()
    let backgroundShape = CAShapeLayer()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawButton()
    }
    
    private func drawButton() {
        self.backgroundColor = UIColor.clear
        
        circleBorder = CALayer()
        circleBorder.backgroundColor = UIColor.clear.cgColor
        circleBorder.borderWidth = 6.0
        circleBorder.borderColor = UIColor.white.cgColor
        circleBorder.bounds = self.bounds
        circleBorder.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        circleBorder.cornerRadius = self.frame.size.width / 2
        layer.insertSublayer(circleBorder, at: 0)
       

    }
    
    
    func updateIndicator(with percent: Double, isAnimated: Bool = false) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressShape.strokeEnd
        animation.toValue = percent / 100.0
        animation.duration = 2.5
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut);
        
        
        let shortestSide = min(self.frame.size.width, self.frame.size.height) - 30
        let strokeWidth: CGFloat = 40.0
        let frame = CGRect(x: 0, y: 0, width: shortestSide - strokeWidth, height: shortestSide - strokeWidth)
        
        
        backgroundShape.frame = frame
        backgroundShape.position = self.center
        backgroundShape.path = UIBezierPath(ovalIn: frame).cgPath
        backgroundShape.strokeColor = UIColor.black.cgColor
        backgroundShape.lineWidth = strokeWidth
        backgroundShape.fillColor = UIColor.clear.cgColor
        
        progressShape.frame = frame
        progressShape.path = backgroundShape.path
        progressShape.position = backgroundShape.position
        progressShape.strokeColor = UIColor.red.cgColor
        progressShape.lineWidth = backgroundShape.lineWidth
        progressShape.fillColor = UIColor.clear.cgColor
        progressShape.strokeEnd = CGFloat(percent/100.0)
        
        if isAnimated {
            progressShape.add(animation, forKey: nil)
        }
        
    }
    
    public  func growButton() {
        progress = 20

        innerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        innerCircle.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        innerCircle.backgroundColor = UIColor.red
        innerCircle.layer.cornerRadius = innerCircle.frame.size.width / 2
        innerCircle.clipsToBounds = true
        self.addSubview(innerCircle)
        
        let outerCircle = UIView(frame: CGRect(x: 20, y: 20, width: 1, height: 1))
        outerCircle.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        outerCircle.backgroundColor = UIColor.red
        outerCircle.layer.cornerRadius = outerCircle.frame.size.width / 2
        outerCircle.clipsToBounds = true
        self.addSubview(outerCircle)
        
        UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseOut, animations: {
            self.innerCircle.transform = CGAffineTransform(scaleX: 62.4, y: 62.4)
            self.circleBorder.setAffineTransform(CGAffineTransform(scaleX: 1.352, y: 1.352))
            self.circleBorder.borderWidth = (6 / 1.352)
            
        }, completion: nil)
        
    }
    
    public func shrinkButton() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.innerCircle.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.circleBorder.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: 1.0))
            self.circleBorder.borderWidth = 6.0
        }, completion: { (success) in
            self.innerCircle.removeFromSuperview()
            self.innerCircle = nil
        })
    }
    
    var progress : Float = 0 {
        didSet {
            if let layer = self.shapelayer {
                layer.strokeEnd = CGFloat(self.progress)
            }
        }
    }
    
    private var shapelayer : CAShapeLayer!
    private var didLayout = false
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !self.didLayout else {return}
        self.didLayout = true
        let layer = CAShapeLayer()
        let bounds = CGRect(x: 50, y: 50, width: 400, height: 400)
        
        layer.frame = bounds
        
        layer.lineWidth = 2
        layer.fillColor = nil
        layer.strokeColor = UIColor.red.cgColor
        let b = UIBezierPath(ovalIn: self.bounds.insetBy(dx: 3, dy: 3))
        b.apply(CGAffineTransform(translationX: -self.bounds.width/2, y: -self.bounds.height/2))
        b.apply(CGAffineTransform(rotationAngle: -.pi/2.0))
        b.apply(CGAffineTransform(translationX: self.bounds.width/2, y: self.bounds.height/2))
        
        layer.path = b.cgPath
        self.layer.addSublayer(layer)
        layer.zPosition = -1
        layer.strokeStart = 0
        layer.strokeEnd = 0
        // layer.setAffineTransform(CGAffineTransform(rotationAngle: -.pi/2.0))
        self.shapelayer = layer
        
    }
    
    
}
