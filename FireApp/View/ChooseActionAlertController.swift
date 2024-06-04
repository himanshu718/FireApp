//
//  ChooseActionAlertController.swift
//  FireApp
//
//  Created by Devlomi on 8/26/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

enum ClickedItem{
    case contact
    case location
    case image
    case camera
}
protocol ChooseActionAlertDelegate {
    func didClick(clickedItem:ClickedItem)
}
class ChooseActionAlertController: UIAlertController {
    

    
    var delegate:ChooseActionAlertDelegate?
   
    
    func setup() {
        title = nil
        message = nil
        
        let imageSize = CGSize(width: 35, height: 35)
        
        let contactAction = UIAlertAction(title: Strings.contact, style: .default) { (_) in
            self.delegate?.didClick(clickedItem: .contact)
        }
        let contactImage = UIImage(named: "person")!.resized(to: imageSize)
        contactAction.setValue(contactImage, forKey: "image")
        
        let locationAction = UIAlertAction(title: Strings.location, style: .default) { (_) in
            self.delegate?.didClick(clickedItem: .location)
        }
        let locationImage = UIImage(named: "location")!.resized(to: imageSize)
        locationAction.setValue(locationImage, forKey: "image")
        
        let imageAction = UIAlertAction(title: Strings.photo_and_video, style: .default) { (_) in
            self.delegate?.didClick(clickedItem: .image)
        }
        let imageLibraryImage = UIImage(named: "image")!.resized(to: imageSize)
        imageAction.setValue(imageLibraryImage, forKey: "image")
        
        let cameraAction = UIAlertAction(title: Strings.camera, style: .default) { (_) in
            self.delegate?.didClick(clickedItem: .camera)
        }
        let cameraImage = UIImage(named: "ic_camera")!.resized(to: imageSize)
        
        
        cameraAction.setValue(cameraImage, forKey: "image")
        
        addAction(cameraAction)
        addAction(imageAction)
        addAction(locationAction)
        addAction(contactAction)

        
    }
    
    
}
