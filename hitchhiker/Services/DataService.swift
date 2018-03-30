//
//  File.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/21/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import Foundation
import Firebase

let DB_BASE = Firestore.firestore()

class DataService {
    
    private static let _instance = DataService()
    
    private var _REF_USERS = DB_BASE.collection("users")
    private var _REF_DRIVERS = DB_BASE.collection("drivers")
    private var _REF_TRIPS = DB_BASE.collection("trips")
    
    static var instance: DataService {
        return _instance
    }
    
    var REF_USERS: CollectionReference {
        return _REF_USERS
    }
    
    var REF_DRIVERS: CollectionReference {
        return _REF_DRIVERS
    }
    
    var REF_TRIPS: CollectionReference {
        return _REF_TRIPS
    }
    
    func createFirestoreDBUser(uid: String, userData: Dictionary<String, Any>, isDriver: Bool) {
        if isDriver {
            REF_DRIVERS.document(uid).setData(userData)
        } else {
            REF_USERS.document(uid).setData(userData)
        }
    }
    
    func driverIsAvailable(key: String, handler: @escaping (_ status: Bool?) -> Void) {
        DataService.instance.REF_DRIVERS.document(key).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if (data["isPickupModeEnabled"] as! Bool) && !(data["driverIsOnTrip"] as! Bool) {
                    handler(true)
                } else {
                    handler(false)
                }
            } else {
                print("error occurred, no driver found from UID")
            }
        }
    }
}

