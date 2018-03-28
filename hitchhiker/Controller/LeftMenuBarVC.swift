//
//  LeftMenuBarVC.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/17/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import Firebase

class LeftMenuBarVC: UIViewController {
    
    let currentUserID = Auth.auth().currentUser?.uid
    let appDelegate = AppDelegate.getAppDelegate()

    @IBOutlet weak var userEmailLbl: UILabel!
    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var loginOutBtn: UIButton!
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    @IBOutlet weak var pickupModeLbl: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pickupModeSwitch.isOn = false
        pickupModeSwitch.isHidden = true
        pickupModeLbl.isHidden = true
        
        
        
        if Auth.auth().currentUser == nil {
            userEmailLbl.text = ""
            userAccountTypeLbl.text = ""
            userImageView.isHidden = true
            loginOutBtn.setTitle("Sign Up / Login", for: .normal)
        } else {
            observePassengersAndDrivers()
            userEmailLbl.text = Auth.auth().currentUser?.email
            userAccountTypeLbl.text = ""
            userImageView.isHidden = false
            loginOutBtn.setTitle("Logout", for: .normal)
            
        }
    }
    
    func observePassengersAndDrivers() {
        //let userRef = DataService.instance.REF_USERS.document((Auth.auth().currentUser?.uid)!)
        
        DataService.instance.REF_USERS.getDocuments { (snapshot, error) in
            if let snapshot = snapshot?.documents {
                for snap in snapshot {
                    if snap.documentID == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "PASSENGER"
                    }
                }
            }
        }
        
        DataService.instance.REF_DRIVERS.getDocuments { (snapshot, error) in
            if let snapshot = snapshot?.documents {
                for snap in snapshot {
                    if snap.documentID == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "DRIVER"
                        self.pickupModeLbl.isHidden = false
                        self.pickupModeSwitch.isHidden = false
                        let data = snap.data()
                        let switchStatus = data["isPickupModeEnabled"] as! Bool
                        self.pickupModeSwitch.isOn = switchStatus
                        
                    }
                }
            }
        }
    }

    @IBAction func switchWasToggled(_ sender: Any) {
        if pickupModeSwitch.isOn {
            pickupModeLbl.text = "PICKUP MODE ENABLED"
            appDelegate.containerVC.toggleLeftMenu()
            DataService.instance.REF_DRIVERS.document((Auth.auth().currentUser?.uid)!).updateData(["isPickupModeEnabled" : true])
        } else {
            pickupModeLbl.text = "PICKUP MODE DISABLED"
            appDelegate.containerVC.toggleLeftMenu()
            DataService.instance.REF_DRIVERS.document((Auth.auth().currentUser?.uid)!).updateData(["isPickupModeEnabled" : false])
        }
    }
    
    @IBAction func signupBtnPressed(_ sender: Any) {
        
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                userEmailLbl.text = ""
                userAccountTypeLbl.text = ""
                userImageView.isHidden = true
                pickupModeLbl.text = ""
                pickupModeSwitch.isHidden = true
                loginOutBtn.setTitle("Sign Up / Login", for: .normal)
            } catch (let error) {
                print(error)
            }
        }
    }
    

}
