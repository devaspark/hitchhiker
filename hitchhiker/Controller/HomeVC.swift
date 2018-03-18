//
//  HomeVC.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/15/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import MapKit

class HomeVC: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    
    var delegate: CenterVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self

        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func actionBtnPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBOutlet weak var menuBtnPressed: UIButton!
    
    @IBAction func menuBtnPressed(_ sender: UIButton) {
        delegate?.toggleLeftMenu()
    }
    
}

