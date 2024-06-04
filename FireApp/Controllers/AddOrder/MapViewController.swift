//
//  MapViewController.swift
//  FireApp
//
//  Created by Kartik Gupta on 02/12/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol mapViewDelegate: AnyObject {
    func selectedLocation(location: CLLocationCoordinate2D)
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    let locationManager = CLLocationManager()
    
    var delegate: mapViewDelegate!
    
    @IBOutlet weak var mapView: MKMapView!
    
    let annotation = MKPointAnnotation()
    
    var isFirstTime = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        mapView.mapType = .hybrid
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true

        if let coor = mapView.userLocation.location?.coordinate{
            mapView.setCenter(coor, animated: true)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        mapView.addGestureRecognizer(tapGesture)
        // Do any additional setup after loading the view.
    }


    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        
        mapView.removeAnnotation(annotation)
        
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Add annotation:
        addAnnotation(location: coordinate)
        
    }
    
    @IBAction func selectBtnTapped(_ sender: Any) {
        print(mapView.region.center)
        delegate.selectedLocation(location: mapView.region.center)
        navigationController?.popViewController(animated: true)
    }

    func addAnnotation(location: CLLocationCoordinate2D){
        annotation.coordinate = location
        self.mapView.addAnnotation(annotation)
        
        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, isFirstTime {
            isFirstTime = false
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapViewController {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { print("no mkpointannotaions"); return nil }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .infoDark)
            pinView!.pinTintColor = UIColor.black
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if let doSomething = view.annotation?.title! {
               print("do something")
            }
        }
    }
}
