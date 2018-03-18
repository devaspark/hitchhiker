//
//  RoundedShadowButton.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/17/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowButton: UIButton {
    
    var _originalSize: CGRect?

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        _originalSize = self.frame
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.masksToBounds = false
    }
    
    func animateButton(shouldLoad: Bool, withMessage message: String?){
        let spinner = UIActivityIndicatorView()
        spinner.activityIndicatorViewStyle = .whiteLarge
        spinner.color = UIColor.darkGray
        spinner.alpha = 0.0
        spinner.hidesWhenStopped = true
        spinner.tag = 21
        
        if shouldLoad {
            self.addSubview(spinner)
            self.setTitle("", for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.cornerRadius = self.frame.height / 2
                self.frame = CGRect(x: self.frame.midX - (self.frame.height / 2), y: self.frame.origin.y, width: self.frame.height, height: self.frame.height)
            }, completion: { (finished) in
                if finished == true {
                    spinner.startAnimating()
                    spinner.center = CGPoint(x: (self.frame.width / 2) + 1, y: (self.frame.width / 2) + 1)
                    UIView.animate(withDuration: 0.2, animations: {
                        spinner.alpha = 1.0
                    })
                }
            })
            self.isUserInteractionEnabled = false
        } else {
            self.isUserInteractionEnabled = true
            
            for subview in self.subviews {
                if subview.tag == 21 {
                    subview.removeFromSuperview()
                }
            }
            
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.cornerRadius = 5.0
                self.frame = self._originalSize!
                self.setTitle(message, for: .normal)
            })
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.0 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
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
