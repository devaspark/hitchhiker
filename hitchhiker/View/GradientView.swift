//
//  GradientView.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/15/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit

class GradientView: UIView {

    let gradient = CAGradientLayer()
    
    override func awakeFromNib() {
        setupGradientView()
    }
    
    override func layoutSubviews() {
        
        gradient.frame.size.width = UIScreen.main.bounds.width
        gradient.frame.size.height = self.frame.height
        super.layoutSubviews()
        self.bringSubview(toFront: self.subviews.first!) 
    }
    
    func setupGradientView() {
        gradient.frame = self.bounds
        gradient.colors = [UIColor.white.cgColor, UIColor.init(white: 1.0, alpha: 0.0).cgColor]
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0.8, 1.0]  //0.8 is where the first color should stop, 1.0 is where the 2nd color should stop
        self.layer.addSublayer(gradient)
    }

}
