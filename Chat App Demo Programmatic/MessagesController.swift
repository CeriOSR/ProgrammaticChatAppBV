//
//  ViewController.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2016-12-31.
//  Copyright © 2016 CeriOS. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Message", style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
    }
    
    func handleNewMessage() {
        
        let newMessageController = NewMessageController()
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController , animated: true, completion: nil)
        
    }
    
    func checkIfUserIsLoggedIn(){
        
        if FIRAuth.auth()?.currentUser?.uid == nil {
            //this way it gets rid of the warning that we are presenting too many viewControllers at startup
            //delay of 0 still has a very little delay so this works.
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            let uid = FIRAuth.auth()?.currentUser?.uid
            FIRDatabase.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
                
                //assigning the value of snapshot into a dictionary so we can pull out the details
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    //assigning the value of name into navigation bar
                    self.navigationItem.title = dictionary["name"] as? String
                }
            }, withCancel: nil)
            
        }

        
    }
    
    func handleLogout() {
        
        do {
            
            try FIRAuth.auth()?.signOut()
            
        } catch let err {
            
            print(err)
            
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
        
    }
    
    

}

