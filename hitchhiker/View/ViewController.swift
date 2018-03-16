//
//  ViewController.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/15/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }


}

