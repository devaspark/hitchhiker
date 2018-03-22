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
                    print("did it get here")
                    self.handleFirebaseError(error: error! as NSError)
                } else {
                    //never get here due to if let errorCode = AuthErrorCode section above. Error already exist
                }
            } else {
                print("auto logged in")
                onComplete!(false, "")
                
            }
        }
    }
    
    func handleFirebaseError(error: NSError) {
        print(error.debugDescription)
        if let errorCode = AuthErrorCode(rawValue: error.code) {
            switch(errorCode) {
            case .invalidEmail:
                print("Invalid email address")
                break
            case .wrongPassword:
                print("Invalid password")
                break
            case .emailAlreadyInUse, .accountExistsWithDifferentCredential:
                print("Could not create account, Email already in use")
                break
            default:
                print("There was a problem authenticating. Try again.")
                
            }
            
        }
    }
}
