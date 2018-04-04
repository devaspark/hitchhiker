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
    
    func driverIsOnTrip(driverKey: String, handler: @escaping (_ status: Bool?, _ driverKey: String?, _ tripKey: String?) -> Void) {
        DataService.instance.REF_DRIVERS.document(driverKey).addSnapshotListener { (driverTripSnapshot, error) in
            if let driverTripSnapshot = driverTripSnapshot, driverTripSnapshot.exists {
                let data = driverTripSnapshot.data()
                if data["driverIsOnTrip"] as! Bool == true {
                    DataService.instance.REF_TRIPS.whereField("driverKey", isEqualTo: driverKey).getDocuments(completion: { (tripQuery, error) in
                        if !(tripQuery?.isEmpty)! {
                            let tripDocs = tripQuery?.documents
                            if let tripDocs = tripDocs {
                                if tripDocs.count > 1 {
                                    print("Error! driver is registered to multiple trips.")
                                    //error occurred, driver is registered to multiple trips
                                    
                                    let tripDocument = tripDocs.first
                                    handler(true, driverKey, tripDocument?.documentID)
                                } else {
                                    let tripDocument = tripDocs.first  //only one element expected so we just take the first one.
                                    handler(true, driverKey, tripDocument?.documentID)
                                }
                            } else {
                                //nothing in tripdocs
                                return
                            }
                        } else {
                            //tripquery empty, did not find trip with the same driver
                        }
                    })
                } else {
                    //driverIsOnTrip is false
                    handler(false, nil, nil)
                }
            }
        }
    }
    
    func passengerIsOnTrip(passengerKey: String, handler: @escaping (_ status: Bool?, _ driverKey: String?, _ tripKey: String?) -> Void) {
        DataService.instance.REF_TRIPS.document(passengerKey).getDocument { (tripDocument, error) in
            if let tripDocument = tripDocument, tripDocument.exists {
                let tripData = tripDocument.data()
                if tripData["tripIsAccepted"] as? Bool == true {
                    let driverKey = tripData["driverKey"] as? String
                    handler(true, driverKey, tripDocument.documentID)
                } else {
                    handler(false, nil, nil)
                }
            }
        }
    }
    
    func userIsDriver(userKey: String, handler: @escaping (_ status: Bool) -> Void) {
        DataService.instance.REF_DRIVERS.document(userKey).getDocument { (driverDocument, error) in
            if let driverDocument = driverDocument, driverDocument.exists {
                handler(true)
            } else {
                handler(false)
            }
        }
    
    
    }
}

