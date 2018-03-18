//
//  LeftMenuBarVC.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/17/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit

class LeftMenuBarVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func signupBtnPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
        present(loginVC!, animated: true, completion: nil)
    }
    

}
