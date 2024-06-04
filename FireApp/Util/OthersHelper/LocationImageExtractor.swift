//
//  LocationImageExtractor.swift
//  FireApp
//
//  Created by Devlomi on 1/25/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
import MapKit

class LocationImageExtractor {
    static func getMapImage(location: CLLocation, complete: (@escaping (UIImage?) -> Void)) {

        let mapSnapshotOptions = MKMapSnapshotter.Options()



        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapSnapshotOptions.region = region

        // Set the scale of the image. We'll just use the scale of the current device, which is 2x scale on Retina screens.
        mapSnapshotOptions.scale = UIScreen.main.scale

        // Set the size of the image output.
        mapSnapshotOptions.size = CGSize(width: 300, height: 300)

        // Show buildings and Points of Interest on the snapshot
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true



        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)

        snapShotter.start { (snapshot, error) in
            guard let snapshot = snapshot, error == nil else {
                return
            }

            UIGraphicsBeginImageContextWithOptions(mapSnapshotOptions.size, true, 0)
            snapshot.image.draw(at: .zero)

            let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let pinImage = pinView.image

            var point = snapshot.point(for: location.coordinate)

            //            if rect.contains(point) {
            let pinCenterOffset = pinView.centerOffset
            point.x -= pinView.bounds.size.width / 2
            point.y -= pinView.bounds.size.height / 2
            point.x += pinCenterOffset.x
            point.y += pinCenterOffset.y
            pinImage?.draw(at: point)
            //            }

            let image = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()
            complete(image)
        }
    }
}
