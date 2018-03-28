//
//  DriverAnnotation.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/27/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import MapKit

class DriverAnnotation: NSObject, MKAnnotation {
   
    @objc dynamic var coordinate: CLLocationCoordinate2D
    private var _key: String
    
    var key: String {
        return _key
    }
    
    init(coordinate: CLLocationCoordinate2D, withKey key: String) {
        self.coordinate = coordinate
        _key = key
        super.init()
    }
    
    func update(annotationPosition annotation: DriverAnnotation, withCoordinate coordinate: CLLocationCoordinate2D) {
        var location = self.coordinate
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        UIView.animate(withDuration: 0.2) {
            self.coordinate = location
        }
    }
    

}
