//
//  UIViewExt.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/18/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit

extension UIView {
    
    func fadeTo(alphaValue: CGFloat, withDuration duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.alpha = alphaValue
        }
    }
}
