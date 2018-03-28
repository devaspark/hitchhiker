//
//  HomeVC.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/15/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation
import RevealingSplashView

class HomeVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    
    var delegate: CenterVCDelegate?
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocationAuthStatus()
        
        mapView.delegate = self
        
        centerMapOnUserLocation()
        
        
        DataService.instance.REF_DRIVERS.addSnapshotListener { (querySnapshot, error) in
            self.loadDriverAnnoationsFromFB()
            self.removeDriverAnnoationsFromFB()
        }
        
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            manager?.startUpdatingLocation()
        } else {
            manager?.requestAlwaysAuthorization()
        }
    }
    
    func loadDriverAnnoationsFromFB() {
        DataService.instance.REF_DRIVERS.whereField("isPickupModeEnabled", isEqualTo: true).whereField("userIsDriver", isEqualTo: true).getDocuments { (querySnapshot, error) in
            if let drivers = querySnapshot?.documents{
                for driver in drivers {
                    let fields = driver.data()
                    if let coordinateArray = fields["coordinate"] as? NSArray {
                        let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                        let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.documentID)
                        var driverIsVisible: Bool {
                            return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                if let driverAnnotation = annotation as? DriverAnnotation {
                                    if driverAnnotation.key == driver.documentID {
                                        driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                        return true
                                    }
                                }
                                return false
                            })
                        }
                        
                        if !driverIsVisible {
                            self.mapView.addAnnotation(annotation)
                        }
                    }
                }
            }
        }
    }
    
    func removeDriverAnnoationsFromFB() {
        DataService.instance.REF_DRIVERS.whereField("isPickupModeEnabled", isEqualTo: false).whereField("userIsDriver", isEqualTo: true).getDocuments { (querySnapshot, error) in
            if let drivers = querySnapshot?.documents{
                for driver in drivers {
                    _ = self.mapView.annotations.contains(where: { (annotation) -> Bool in
                            if let driverAnnotation = annotation as? DriverAnnotation {
                                if driverAnnotation.key == driver.documentID {
                                    self.mapView.removeAnnotation(annotation)
                                    return true
                                }
                            }
                            return false
                    })
                }
            }
        }
    }
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    @IBAction func actionBtnPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBOutlet weak var menuBtnPressed: UIButton!
    
    @IBAction func menuBtnPressed(_ sender: UIButton) {
        delegate?.toggleLeftMenu()
    }
    
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }
}

extension HomeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse{
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    
    
}

extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if (Auth.auth().currentUser != nil) {
            //Todo: detect which type of user is here, need to separate out user and driver location
            if let userIsDriver = AuthService.instance.isDriver {
                if userIsDriver == true {
                    LocationService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
                }
                
                if userIsDriver == false {
                    LocationService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        }
        
        return nil
    }
}









