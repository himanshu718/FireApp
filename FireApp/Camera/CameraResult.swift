//
//  CameraResult.swift
//  FireApp
//
//  Created by Devlomi on 6/29/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import Foundation
import UIKit
protocol CameraResult {
    func imageTaken(image :UIImage?)  
    func videoTaken(videoUrl:URL)
}
