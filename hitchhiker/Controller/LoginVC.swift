//
//  LoginVC.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/18/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController, UITextFieldDelegate, Alertable {

    @IBOutlet weak var emailField: RoundedCornerTextField!
    @IBOutlet weak var passwordField: RoundedCornerTextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var authBtn: RoundedShadowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AuthService.instance.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        view.bindToKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    @IBAction func cancelBtnPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func authBtnPressed(_ sender: Any) {
        if emailField.text != nil && passwordField != nil {
            authBtn.animateButton(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            
            if let email = emailField.text, let password = passwordField.text {
                if self.segmentedControl.selectedSegmentIndex == 0 {
                    AuthService.instance.login(email: email, password: password, isDriver: false, onComplete: { (isError, errorMsg) in
                        if(!isError){
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                    
                    
                } else {
                    AuthService.instance.login(email: email, password: password, isDriver: true, onComplete: { (isError, errorMsg) in
                        if(!isError){
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            }
        }
    }
    
}
