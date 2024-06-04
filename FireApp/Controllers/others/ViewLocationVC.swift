//
//  ViewLocationVC.swift
//  FireApp
//
//  Created by Devlomi on 8/31/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import MapKit

class ViewLocationVC: BaseVC {

    private var location:RealmLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let mapView = MKMapView(frame: view.frame)
        view.addSubview(mapView)
        
        
        guard let location = location else {
            return
        }
        
        let coord = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
        
        let anno = MKPointAnnotation();
        anno.coordinate = coord
        mapView.addAnnotation(anno)

        let region = MKCoordinateRegion(center: coord, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)

        
        
    }
    
    func initialize(location:RealmLocation) {
        self.location = location
    }


}
