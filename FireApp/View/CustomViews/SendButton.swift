//
//  SendButton.swift
//  FireApp
//
//  Created by Devlomi on 8/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import iRecordView

enum ButtonState {
    case toRecord
    case toSend
}

let micImage = UIImage(named: "mic_none")
let sendImage = UIImage(named: "send")

class SendButton: RecordButton {
    
    //increase tapable area
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
           let newArea = CGRect(
               x: self.bounds.origin.x - 5.0,
               y: self.bounds.origin.y - 5.0,
               width: self.bounds.size.width + 10.0,
               height: self.bounds.size.height + 20.0
           )
           return newArea.contains(point)
       }

    
    var currentState: ButtonState = .toRecord

    func animate(state: ButtonState) {
        if state == currentState {
            return
        }

        listenForRecord = state == .toRecord
        currentState = state
        let translationY: CGFloat = 350

        let newImage = currentState == .toRecord ? micImage : sendImage

        let animationDuration = 0.15

        UIView.animate(withDuration: animationDuration, animations: {
            self.transform = CGAffineTransform(translationX: translationY, y: 0)
        }) { (_) in
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.transform = CGAffineTransform(translationX: 0, y: 0)
                self.setImage(newImage, for: .normal)

            }, completion: { (_) in
                    if self.image(for: .normal) != newImage {
                        self.setImage(newImage, for: .normal)
                    }

                })


        }
    }
}
