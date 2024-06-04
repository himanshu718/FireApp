//
//  CustomProgressButton.swift
//  FireApp
//
//  Created by Devlomi on 9/8/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import CircleProgressButton

class CustomProgressButton: CircleProgressButton {

    var downloadUploadState: DownloadUploadState = .DEFAULT {
        didSet {
            switch downloadUploadState {
            case .CANCELLED, .FAILED:
                self.suspend()

            case .LOADING:
                self.resume()
                self.strokeMode = .border(width: 4)

            case .SUCCESS:
                self.strokeMode = .fill
                self.complete()
            default:
                break
            }
        }
    }


    var isSentType = false




    var iconTintColor: UIColor = .black {
        didSet {
            animationEnableOptions = .iconScale

            inProgressStrokeColor = UIColor.red
            suspendedStrokeColor = UIColor(hexString: "0x8C8C8C")
            completedStrokeColor = UIColor(hexString: "0x0044C3")
            strokeMode = .fill
        }
    }




    override var defaultImage: UIImage? {
        set { }

        get {
            let imageName = isSentType ? "upload" : "download"
            return UIImage(named: imageName)?.tinted(with: iconTintColor)

        }
    }

    override var inProgressImage: UIImage? {
        set { }
        get { return UIImage(named: "close")?.tinted(with: iconTintColor) }
    }


    override var suspendedImage: UIImage? {
        set { }
        get { return defaultImage }
    }


    override var completedImage: UIImage? {
        set { }
        get { return defaultImage }
    }
}
