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
        let userRef = DataService.instance.REF_USERS.document((Auth.auth().currentUser?.uid)!)
        userRef.getDocument { (docSnapshot, error) in
            if error == nil {
                DataService.instance.REF_USERS.document((Auth.auth().currentUser?.uid)!).updateData(["coordinate": [coordinate.latitude, coordinate.longitude]])
            } else {
                print("Error occurred fetching user data for location update")
            }
        }
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        let driverRef = DataService.instance.REF_DRIVERS.document((Auth.auth().currentUser?.uid)!)
        driverRef.getDocument { (docSnapshot, error) in
            if error == nil {
                print("did it get here?")
                let data = docSnapshot?.data()
                print((Auth.auth().currentUser?.uid)!)
                print(data)
                let pickupModeStatus = data!["isPickupModeEnabled"] as! Bool
                if pickupModeStatus == true {
                    print("did it get into pickup model enabled")
                    DataService.instance.REF_DRIVERS.document((Auth.auth().currentUser?.uid)!).updateData(["coordinate": [coordinate.latitude, coordinate.longitude]])
                }
            } else {
                print("Error occurred fetching driver data for location update")
            }
        }
    }
}
