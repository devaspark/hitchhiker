//
//  AuthService.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/21/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import Foundation
import Firebase

typealias CompletionHandler = (_ error: Bool, _ msg: String) -> Void

class AuthService {
    
    private static let _instance = AuthService()
    
    static var instance: AuthService {
        return _instance
    }
    
    private var _isDriver: Bool?
    var delegate: Alertable?
    
    var isDriver: Bool? {
        get {
            return _isDriver
        }
        set {
            _isDriver = newValue
        }
    }
    
    func login(email: String, password: String, isDriver: Bool, onComplete: CompletionHandler?) {
        var userData: Dictionary<String, Any>?
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error != nil {
                if let errorCode = AuthErrorCode(rawValue: (error?._code)!) {
                    if errorCode == .userNotFound {
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                //error creating user
                            } else {
                                if user?.uid != nil {
                                    if (isDriver) {
                                        userData = ["provider": user?.providerID as Any, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false]
                                    } else {
                                        userData = ["provider": user?.providerID] as! [String: String]
                                    }
                                    DataService.instance.createFirestoreDBUser(uid: (user?.uid)!, userData: userData!, isDriver: isDriver)
                                    Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                                        if error != nil {
                                            // error logging in
                                            self.handleFirebaseError(error: error! as NSError)
                                            onComplete!(true, "Please Try Again")
                                        } else {
                                            // user created account and logged in
                                            print("************logged in")
                                            onComplete!(false, "")
                                        }
                                    })
                                }
                            }
                            
                        })
                    }
                    self.handleFirebaseError(error: error! as NSError)
                } else {
                    //never get here due to if let errorCode = AuthErrorCode section above. Error already exist
                }
            } else {
                onComplete!(false, "")
                
            }
        }
    }
    
    func handleFirebaseError(error: NSError) {
        print(error.debugDescription)
        if let errorCode = AuthErrorCode(rawValue: error.code) {
            switch(errorCode) {
            case .invalidEmail:
                self.delegate?.showAlert("Invalid email address")
                break
            case .wrongPassword:
                self.delegate?.showAlert("Invalid Password")
                break
            case .emailAlreadyInUse, .accountExistsWithDifferentCredential:
                self.delegate?.showAlert("Could not create account, Email already in use")
                break
            default:
                self.delegate?.showAlert("There was a problem authenticating. Try again.")                
            }
            
        }
    }
}
