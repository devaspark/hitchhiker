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

enum AnnotationType {
    case pickup
    case destination
    case driver
}

enum ButtonAction {
    case requestRide
    case getDirectionsToPassenger
    case getDirectionsToDestination
    case startTrip
    case endTrip
}

//fix passenter is on trip

class HomeVC: UIViewController, Alertable, HomeVCDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    @IBOutlet weak var centerMapBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var delegate: CenterVCDelegate?
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    var tableView = UITableView()
    var matchingItems = [MKMapItem]()
    var route: MKRoute!
    var selectedItemPlacemark: MKPlacemark? = nil
    var currentUID: String?       //remember to store this again if the user logs out in the app
    var actionForButton: ButtonAction = .requestRide
    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        cancelBtn.alpha = 0.0
        
        checkLocationAuthStatus()
        currentUID = Auth.auth().currentUser?.uid
        
        mapView.delegate = self
        destinationTextField.delegate = self
        
        
        centerMapOnUserLocation()
        
        
        DataService.instance.REF_DRIVERS.addSnapshotListener { (querySnapshot, error) in
            self.loadDriverAnnoationsFromFB()
            self.removeDriverAnnoationsFromFB()
            
            DataService.instance.passengerIsOnTrip(passengerKey: self.currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            })
        }
        
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        
        LocationService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripKey = tripDict["passengerKey"] as! String
                
                //from listener query, accepted trip is already checked to be false
                DataService.instance.driverIsAvailable(key: self.currentUID!, handler: { (available) in
                    if let available = available {
                        if available == true {
                            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                            let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                            pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                            pickupVC?.homeVCDelegate = self
                            self.present(pickupVC!, animated: true, completion: nil)
                        }
            
                    }
                })
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DataService.instance.userIsDriver(userKey: currentUID!) { (status) in
            if status == true {
                self.buttonsForDriver(areHidden: true)
            }
        }
        
        currentUID = Auth.auth().currentUser?.uid
        
        DataService.instance.REF_TRIPS.addSnapshotListener { (querySnapshot, error) in
            if let querySnapshot = querySnapshot {
                let docChanges = querySnapshot.documentChanges
                for change in docChanges {
                    switch (change.type) {
                    case .added:
                        print("this was added \(change.document.documentID)")
                        break
                    case .modified:
                        print("this was modified \(change.document.documentID)")
                        break
                    case .removed:
                        let data = change.document.data()
                        if data["driverKey"] != nil {
                            self.setDriverTripStatus(driverKey: data["driverKey"] as! String, status: false)
                        }
                        self.cleanUpLocation()
                    }
                }
                
            }
        }
        
        DataService.instance.driverIsOnTrip(driverKey: currentUID!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip != nil, isOnTrip == true {
        
        /*DataService.instance.driverIsAvailable(key: self.currentUID!) { (status) in
            if status == nil {
                print("no driver found")
            }
            if status == false {*/
                switch self.actionForButton {
                case .requestRide:
                
        
                    DataService.instance.REF_TRIPS.whereField("driverKey", isEqualTo: self.currentUID!).getDocuments(completion: { (querySnap, error) in
                        if let documents = querySnap?.documents {
                            let document = documents.first
                            let tripData = document?.data()
                            let pickupCoordinateArray = tripData!["pickupCoordinate"] as! NSArray
                            let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                            let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                            
                            self.dropPinFor(placemark: pickupPlacemark)
                            self.searchMapKitForResultsWithPolyLine(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                            self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: pickupCoordinate)
                            print("this happened HERE **********************************************************************")
                            self.actionForButton = .getDirectionsToPassenger
                            self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                            
                            self.buttonsForDriver(areHidden: false)
                        }
                    })
                default:
                    print("did nothing")
                }
            }
        }
        
        connectUserAndDriverForTrip()
        

    }
    
    func setDriverTripStatus(driverKey: String, status: Bool) {
        DataService.instance.REF_DRIVERS.document(driverKey).setData(["driverIsOnTrip": status], options: SetOptions.merge())
    }

    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            manager?.startUpdatingLocation()
        } else {
            manager?.requestAlwaysAuthorization()
        }
    }
    
    func buttonsForDriver(areHidden: Bool) {
        if areHidden {
            self.actionBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            
            self.actionBtn.isHidden = true
            self.cancelBtn.isHidden = true
            self.centerMapBtn.isHidden = true
        } else {
            self.actionBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.cancelBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)

            self.actionBtn.isHidden = false
            self.cancelBtn.isHidden = false
            self.centerMapBtn.isHidden = false
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
        
        revealingSplashView.heartAttack = true
    }
    
    func connectUserAndDriverForTrip() {
        DataService.instance.passengerIsOnTrip(passengerKey: self.currentUID!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
        //DataService.instance.userIsDriver(userKey: self.currentUID!) { (status) in
            //if status == false {
                print("inside IS ON TIRPERIESFJSDFLKJSDFLK:DSJFL:DSKFJSD:FLDSJKFDS")
                //DataService.instance.REF_TRIPS.document(self.currentUID!).addSnapshotListener({ (docSnapshot, error) in
                DataService.instance.REF_TRIPS.document(self.currentUID!).getDocument(completion: { (docSnapshot, error) in
                    if let docSnapshot = docSnapshot, docSnapshot.exists {
                        let tripData = docSnapshot.data()
                    
                        if tripData["tripIsAccepted"] as? Bool == true {
                            
                            
                            let driverID = tripData["driverKey"] as! String
                            let pickupCoordinateArray = tripData["pickupCoordinate"] as! NSArray
                            let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                            let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                            let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
                            
                            if tripData["tripIsInProgress"] as? Bool == false {
                                DataService.instance.REF_DRIVERS.document(driverID).getDocument(completion: { (docSnapshot, error) in
                                    if let docSnapshot = docSnapshot {
                                        let data = docSnapshot.data()
                                        let driverCoordinateArray = data["coordinate"] as! NSArray
                                        let driverCoordinate = CLLocationCoordinate2D(latitude: driverCoordinateArray[0] as! CLLocationDegrees, longitude: driverCoordinateArray[1] as! CLLocationDegrees)
                                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                                        let driverMapItem = MKMapItem(placemark: driverPlacemark)
                                        
                                        let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, key: self.currentUID!)
                                        let driverAnnotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driverID)
                                        
                                        self.mapView.addAnnotations([passengerAnnotation, driverAnnotation])
                                        self.searchMapKitForResultsWithPolyLine(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                                        self.actionBtn.animateButton(shouldLoad: false, withMessage: "DRIVER COMING")
                                        self.actionBtn.isUserInteractionEnabled = false
                                        
                                    }
                                })
                            }
                            DataService.instance.REF_TRIPS.document(docSnapshot.documentID).getDocument(completion: { (docSnapshot, error) in
                                if tripData["tripIsInProgress"] as? Bool == true {
                                    self.removeOverlaysAndAnnotations(forDrivers: true, forPassengers: true)
                                    
                                    let destinationCoordinateArray = tripData["destinationCoordinate"] as! NSArray
                                    let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                                    let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                                    self.dropPinFor(placemark: destinationPlacemark)
                                    self.searchMapKitForResultsWithPolyLine(forOriginMapItem: pickupMapItem, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                                    
                                    self.actionBtn.setTitle("ON TRIP", for: .normal)
                                }
                            })
                        }
                    }
                })
            } else {
                print("Not inside: isontrip: \(isOnTrip), \(driverKey), \(tripKey)")
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
        buttonSelector(foraction: actionForButton)
    }
    
    
    func buttonSelector(foraction action: ButtonAction) {
        switch action {
        case .requestRide:
        // setup code to request ride
            if destinationTextField.text != "" {
                LocationService.instance.updateTripsWithCoordinatesUponRequest()
                actionBtn.animateButton(shouldLoad: true, withMessage: nil)
                cancelBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
                cancelBtn.isUserInteractionEnabled = true
                self.view.endEditing(true)
                destinationTextField.isUserInteractionEnabled = false
            }
        case .getDirectionsToPassenger:
        //get dir. to pass.
            DataService.instance.driverIsOnTrip(driverKey: currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.document(tripKey!).addSnapshotListener({ (tripSnapshot, error) in
                        if let tripSnapshot = tripSnapshot, tripSnapshot.exists {
                            let tripDict = tripSnapshot.data()
                            
                            let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                            let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                            let pickupMapItem = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate))
                            pickupMapItem.name = "Passenger Pickup Point"
                            pickupMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                        }
                    })
                }
            })
        case .startTrip:
        //start trip
            DataService.instance.driverIsOnTrip(driverKey: self.currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true, self.actionForButton != .getDirectionsToDestination, self.actionForButton != .endTrip {
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: false)
                    print("suspect loop************************************************************")
                    DataService.instance.REF_TRIPS.document(tripKey!).updateData(["tripIsInProgress" : true])
                    
                    DataService.instance.REF_TRIPS.document(tripKey!).getDocument(completion: { (docSnapshot, error) in
                        if let docSnapshot = docSnapshot, docSnapshot.exists {
                            let docData = docSnapshot.data()
                            let destinationCoordinateArray = docData["destinationCoordinate"] as! NSArray
                            let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                            self.dropPinFor(placemark: destinationPlacemark)
                            self.searchMapKitForResultsWithPolyLine(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                            self.setCustomRegion(forAnnotationType: .destination, withCoordinate: destinationCoordinate)
                            //self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: destinationCoordinate)
                            self.actionForButton = .getDirectionsToDestination
                            self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                        }
                    })
                }
            })
            print("start trip selected")
        case .getDirectionsToDestination:
        //dir. to destination.
            DataService.instance.driverIsOnTrip(driverKey: currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.document(tripKey!).addSnapshotListener({ (tripSnapshot, error) in
                        if let tripSnapshot = tripSnapshot, tripSnapshot.exists {
                            let tripData = tripSnapshot.data()
                            let destinationCoordinateArray = tripData["destinationCoordinate"] as! NSArray
                            let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                            destinationMapItem.name = "Passenger Destination"
                            destinationMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                        }
                    })
                }
            })
        case .endTrip:
            //end the trip
            DataService.instance.driverIsOnTrip(driverKey: currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    LocationService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
                    self.buttonsForDriver(areHidden: true)
                }
            })
        }
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        DataService.instance.driverIsOnTrip(driverKey: currentUID!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                LocationService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        
        DataService.instance.passengerIsOnTrip(passengerKey: currentUID!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                LocationService.instance.cancelTrip(withPassengerKey: self.currentUID!, forDriverKey: driverKey!)
            } else {
                LocationService.instance.cancelTrip(withPassengerKey: self.currentUID!, forDriverKey: nil)
            }
        }
        
        cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
        cancelBtn.isUserInteractionEnabled = false
        self.actionBtn.isUserInteractionEnabled = true
    }
    
    @IBOutlet weak var menuBtnPressed: UIButton!
    
    @IBAction func menuBtnPressed(_ sender: UIButton) {
        delegate?.toggleLeftMenu()
    }

    
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        
        if AuthService.instance.isDriver == true {
            DataService.instance.REF_DRIVERS.document(currentUID!).getDocument { (docSnapshot, error) in
                if (docSnapshot?.exists)! {
                    self.centerMapOnUserLocation()
                    self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                }
            }
        } else {
            DataService.instance.REF_USERS.document(currentUID!).getDocument { (docSnapshot, error) in
                if (docSnapshot?.exists)! {
                    let data = docSnapshot?.data()
                    if data!["tripCoordinate"] != nil {
                        self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                        self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    } else {
                        self.centerMapOnUserLocation()
                        self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    }
                }
            }
        }
    }
    
    
    func cleanUpLocation() {
        DataService.instance.userIsDriver(userKey: self.currentUID!) { (isDriver) in
            if isDriver == true {
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
            } else {
                self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                self.cancelBtn.isUserInteractionEnabled = false
                self.actionBtn.animateButton(shouldLoad: false, withMessage: "REQUEST RIDE")
                
                self.destinationTextField.isUserInteractionEnabled = true
                self.destinationTextField.text = ""
                
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                self.centerMapOnUserLocation()
            }
        }
    }
}

extension HomeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse{
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUID!) { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true, self.actionForButton != .endTrip {
                if region.identifier == "pickup" {
                    self.actionForButton = .startTrip
                    self.actionBtn.setTitle("START TRIP", for: .normal)
                    print("Driver entered pickup region")
                } else if region.identifier == "destination" {
                    print("Driver entered destination region")
                    self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.cancelBtn.isHidden = true
                    self.actionForButton = .endTrip
                    self.actionBtn.setTitle("END TRIP", for: .normal)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUID!) { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true, self.actionForButton != .endTrip {
                if region.identifier == "pickup" {
                    // call an action on the button that will load directions to passenger pickup
                    print("Driver exited pickup region")
                    self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                } else if region.identifier == "destination" {
                    // call an action on the button that will load directions to destination
                    print("driver exited destination region")
                    self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                }
            }
        }
    }
}

extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if (Auth.auth().currentUser != nil) {
            //Todo: detect which type of user is here, need to separate out user and driver location
            
            DataService.instance.userIsDriver(userKey: currentUID!, handler: { (isADriver) in
                if isADriver == true {
                    LocationService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
                    DataService.instance.driverIsOnTrip(driverKey: self.currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                        if isOnTrip == true {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                        } else {
                            self.centerMapOnUserLocation()
                        }
                    })
                } else {
                    LocationService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
                    /*DataService.instance.passengerIsOnTrip(passengerKey: self.currentUID!, handler: { (isOnTrip, driverKey, tripKey) in
                        if isOnTrip == true {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                        } else {
                            self.centerMapOnUserLocation()
                        }
                    })*/
                }
            })
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {  //refactor this
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(polyline: self.route.polyline)
        lineRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 3
        shouldPresentLoadingView(false)
        return lineRenderer
    }
    
    func performSearch() {
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { (searchResults, error) in
            if error != nil {
                self.showAlert("Error occurred. Please try again.")
            } else if searchResults?.mapItems.count == 0 {
                self.showAlert("No results! Please search again for a different location.")
            } else {
                for mapItem in searchResults!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
            
        }
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        selectedItemPlacemark = placemark
        
        for anno in mapView.annotations {
            if anno.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(anno)
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func searchMapKitForResultsWithPolyLine(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem) {
        let request = MKDirectionsRequest()
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                self.showAlert("Error occurred, cannot find location")
                return
            }
            self.route = response.routes[0]
            
            //if self.mapView.overlays.count == 0 {
                self.mapView.add(self.route.polyline)
            //}
            
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.self.shouldPresentLoadingView(false)
        }
    }
    
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - ((topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5), topLeftCoordinate.longitude + ((bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5)), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude-bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    func removeOverlaysAndAnnotations(forDrivers: Bool?, forPassengers: Bool?) {
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
            
            if forPassengers! {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            if forDrivers! {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.remove(overlay)
            }
        }
    }
    
    func setCustomRegion(forAnnotationType type: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D) {
        if type == .pickup {
            let pickupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "pickup")
            manager?.startMonitoring(for: pickupRegion)
        } else if type == .destination {
            let destination = CLCircularRegion(center: coordinate, radius: 100, identifier: "destination")
            manager?.startMonitoring(for: destination)
        } else if type == .driver {
            let driverRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "driver")
            manager?.startMonitoring(for: driverRegion)
        }
    }
}



extension HomeVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == destinationTextField {
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 180)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tag = 18
            tableView.rowHeight = 60
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            })
        }

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                })
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        
        DataService.instance.REF_USERS.document(currentUID!).updateData(["tripCoordinate" : FieldValue.delete()]) { (err) in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("trip coordinates successfully deleted")
            }
        }
        mapView.removeOverlays(mapView.overlays)
        for anno in mapView.annotations {
            if let anno = anno as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            } else if anno.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(anno)
            }
        }
        
        
        centerMapOnUserLocation()
        return true
    }
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: 180, width: self.view.frame.width - 40, height: self.view.frame.height - 180)
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 180)
            })
            for subview in view.subviews {
                if subview.tag == 18 {
                    subview.removeFromSuperview()
                }
            }
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldPresentLoadingView(true)
        
        let passengerCoordinate = manager?.location?.coordinate
        
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: currentUID!)
        mapView.addAnnotation(passengerAnnotation)
        
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        let selectedMapItem = matchingItems[indexPath.row]
        
        guard let currentUID = currentUID else {return}
        DataService.instance.REF_USERS.document(currentUID).setData(["tripCoordinate" : [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]], options: SetOptions.merge())
        
        dropPinFor(placemark: selectedMapItem.placemark)
        
        searchMapKitForResultsWithPolyLine(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}









