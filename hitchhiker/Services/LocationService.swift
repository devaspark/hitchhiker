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
}
