//
//  LocationService.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/27/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Firebase

class LocationService {
    static var instance = LocationService()
    
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = DataService.instance.REF_USERS.document(uid)
        userRef.getDocument { (docSnapshot, error) in
            if error == nil {
                DataService.instance.REF_USERS.document(uid).setData(["coordinate": [coordinate.latitude, coordinate.longitude]], options: SetOptions.merge())
            } else {
                print("Error occurred fetching user data for location update")
            }
        }
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let driverRef = DataService.instance.REF_DRIVERS.document(uid)
        
        driverRef.getDocument { (docSnapshot, error) in
            if error == nil {
                let data = docSnapshot?.data()
                let pickupModeStatus = data!["isPickupModeEnabled"] as! Bool
                if pickupModeStatus == true {
                    //guard let uid = Auth.auth().currentUser?.uid else {return}
                    DataService.instance.REF_DRIVERS.document(uid).setData(["coordinate": [coordinate.latitude, coordinate.longitude]], options: SetOptions.merge())
                }
            } else {
                print("Error occurred fetching driver data for location update")
            }
        }
    }
    
    func observeTrips(handler: @escaping (_ coordinateDict: Dictionary<String, Any>?) -> Void) {
        DataService.instance.REF_TRIPS.whereField("tripIsAccepted", isEqualTo: false).addSnapshotListener { (docSnapshot, error) in
            guard let documents = docSnapshot else { return }
            documents.documentChanges.forEach({ (diff) in
                if (diff.type == .added) {
                    //New Trip added
                    let data = diff.document.data()
                    handler(data)
                }
                if (diff.type == .modified) {
                    //modified trip
                    let data = diff.document.data()
                    handler(data)
                }
                if (diff.type == .removed) {
                    //removed trip
                }
            })
        }
    }
    
    func updateTripsWithCoordinatesUponRequest() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = DataService.instance.REF_USERS.document(uid)
        userRef.getDocument { (userDoc, error) in
            let data = userDoc?.data()
            let pickupArray = data!["coordinate"] as! NSArray
            let destinationArray = data!["tripCoordinate"] as! NSArray
            
            DataService.instance.REF_TRIPS.document(uid).setData(["pickupCoordinate" : [pickupArray[0], pickupArray[1]], "destinationCoordinate" : [destinationArray[0], destinationArray[1]], "passengerKey" : uid, "tripIsAccepted": false], options: SetOptions.merge())
        }
    }
    
    func acceptTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String) {
        DataService.instance.REF_TRIPS.document(passengerKey).setData(["driverKey" : driverKey, "tripIsAccepted": true], options: SetOptions.merge())
        DataService.instance.REF_DRIVERS.document(driverKey).setData(["driverIsOnTrip" : true], options: SetOptions.merge())
    }
    
    func cancelTrip(withPassengerKey passengerKey:String, forDriverKey driverkey: String) {
        DataService.instance.REF_TRIPS.document(passengerKey).delete()
        DataService.instance.REF_USERS.document(passengerKey).updateData(["tripCoordinate" : FieldValue.delete()])
        DataService.instance.REF_DRIVERS.document(driverkey).setData(["driverIsOnTrip" : false], options: SetOptions.merge())
    }
}
