//
//  PassengerAnnotation.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/28/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    
    private var _key: String
    
    var key: String {
        return _key
    }
    
    init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        _key = key
        super.init()
    }
    
    
}
