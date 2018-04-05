//
//  CenterVCDelegate.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/18/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func toggleLeftMenu()
    func addLeftMenuViewController()
    func animateLeftMenu(shouldExpand: Bool)    
}
