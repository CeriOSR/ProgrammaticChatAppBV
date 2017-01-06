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
    
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "New Message", style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        observeMessages()
        
    }
    
    //use to store messages
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    func observeMessages() {
        
        let ref = FIRDatabase.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let message = Message()
                message.setValuesForKeys(dictionary)
                //self.messages.append(message)
                
                //were trying to set up a dictionary of [toId: Messages] with 1 message per toId...working on getting the latest message per Id.
                if let toId = message.toId {
                    self.messagesDictionary[toId] = message
                    //messages is an array so we convert the messagesDictionary into an array...Confusing? Yes!!!
                    self.messages = Array(self.messagesDictionary.values)
                    
                    //this is how you sort an array, so our tableView are sorted by timestamp in decending order
                    self.messages.sort(by: { (message1, message2) -> Bool in
                        return (message1.timeStamp?.intValue)! > (message2.timeStamp?.intValue)!
                    })
                
                }
                
                //this will crash because its on background thread, so lets dispatch this to be async with main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()

                }
            }
            
        }, withCancel: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    //changes height of cells
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    func handleNewMessage() {
        
        let newMessageController = NewMessageController()
        //messagesController will return a nil and will not bring up the VC so we set it a value of it here
        //***this was the solution to our previous problem from the other apps.***
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController , animated: true, completion: nil)
        
    }
    
    func checkIfUserIsLoggedIn(){
        
        if FIRAuth.auth()?.currentUser?.uid == nil {
            //this way it gets rid of the warning that we are presenting too many viewControllers at startup
            //delay of 0 still has a very little delay so this works.
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            
            fetchUserAndSetupNavBarTitle()
            
        }
        
    }
    
    //putting this into a method so we can call it when registering too not just logging in.
    func fetchUserAndSetupNavBarTitle() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            //assigning the value of snapshot into a dictionary so we can pull out the details
            if let dictionary = snapshot.value as? [String: AnyObject] {
                //assigning the value of name into navigation bar
//                self.navigationItem.title = dictionary["name"] as? String
                
                //setting up nav bar with user Image, not just the name
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user: user)
            }
        }, withCancel: nil)
        
    }
    
    func setupNavBarWithUser(user: User) {
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        //titleView.backgroundColor = UIColor.red
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        //declaring the profileImageView
        let profileImageView = UIImageView()
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 20
        profileImageView.layer.masksToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        containerView.addSubview(profileImageView)
        
        //ios9 constraints x, y, width, height: profileImageView
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        //declaring nameLabel
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabel)

        
        //ios9 constraints x, y, width, height: nameLabel
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        //ios9 constraints x, y, w, h: containerView...We use this containerView to center the expand the label and profileImage because the titleView is not expandable due to constant.
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        
        self.navigationItem.titleView = titleView
        
        //titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        
    }
    
    func showChatControllerForUser(user: User) {
        
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    func handleLogout() {
        
        do {
            
            try FIRAuth.auth()?.signOut()
            
        } catch let err {
            
            print(err)
            
        }
        //need a reference to messagesController so it wont return nil and present() will go through
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
        
    }
    
    

}

