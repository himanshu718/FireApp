//
//  RouteViewController.swift
//  FireApp
//
//  Created by Kartik Gupta on 04/12/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit
import MapKit

class RouteViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var order: Order!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
//        if let pickupLatitude = order.pickupLatLng?["latitude"], let pickupLongitude = order.pickupLatLng?["longitude"], let deliveryLatitude = order.deliveryLatLng?["latitude"], let deliveryLongitude = order.deliveryLatLng?["longitude"] {
//            let pickUpCoordinates = CLLocationCoordinate2DMake(CLLocationDegrees(pickupLatitude), CLLocationDegrees(pickupLongitude))
//            let deliveryCoordinates = CLLocationCoordinate2DMake(CLLocationDegrees(deliveryLatitude), CLLocationDegrees(deliveryLongitude))
//
//            showRouteOnMap(pickupCoordinate: pickUpCoordinates, destinationCoordinate: deliveryCoordinates)
//
//            let pickUpLocation = CLLocation(latitude: pickupLatitude, longitude: pickupLongitude)
//            let deliveryLocation = CLLocation(latitude: deliveryLatitude, longitude: deliveryLongitude)
//            let distanceInMeters = pickUpLocation.distance(from: deliveryLocation)
//            let distance = distanceInMeters/1000
//            distanceLabel.text = "\(Double(round(100 * distance) / 100)) KM"
//        }
        
        // Do any additional setup after loading the view.
    }
    
    
     /*
     //MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            //for getting just one route
            if let route = unwrappedResponse.routes.first {
                //show on map
                self.mapView.addOverlay(route.polyline)
                //set the map area to show the route
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
            }
            
            //if you want to show multiple routes then you can get all routes in a loop in the following statement
            //for route in unwrappedResponse.routes {}
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 5.0
        return renderer
    }
}
