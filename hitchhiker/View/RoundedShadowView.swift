//
//  RoundedShadowView.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/16/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowView: UIView {
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.masksToBounds = false
    }

    @IBInspectable var cornerRadius: CGFloat = 5.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.3 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }
    
    /*@IBInspectable var shadowColor: CGColor = UIColor.darkGray.cgColor {
        didSet {
            layer.shadowColor = shadowColor
        }
    }*/
    
    @IBInspectable var shadowRadius: CGFloat = 5.0 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }
    
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0, height: 5) {
        didSet {
            layer.shadowOffset = shadowOffset
        }
    }

}
