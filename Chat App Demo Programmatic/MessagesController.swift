//
//  MessagesController.swift
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "new_message_icon"), style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        //observeMessages()
        
        //1st of 3 steps needed to reveal the swipe to delete functionality
        tableView.allowsMultipleSelectionDuringEditing = true
        
    }
    
    //2nd step needed to do swipe to delete functionality
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        
        //no need to unwrap because its not an optional (var is just below this method)
        let message = self.messages[indexPath.row]
            
        if let chatPartnerId = message.chatPartnerId() {
            
            FIRDatabase.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    
                    print("failed to delete message", error ?? "")
                    return
                }
                
//                //one way of updating the table but not completely the right way because its unsafe because it deletes the reference but does not delete the actual message in "messages" child or from [messageDictionary]
//                self.messages.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                
                //right way
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadTable()
                
            })
            
        }
        
        
    }
    
    //use to store messages
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    //observing only last message per user by fanning out
    func obeserveUserMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        //first we observe the id's of the messages that belongs to current user in the "user-messages" node
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)

        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            //added another node to specify both parties and reduce the fetch request...hence reduce cost!!!!!!!!!
            FIRDatabase.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
        
        }, withCancel: nil)
        
        //if we delete message from the outside source or manually in firebase, it should automatically be deleted in the app
        ref.observe(.childRemoved, with: { (snapshot) in
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadTable()
        }, withCancel: nil)
        
    }
    
    private func fetchMessageWithMessageId(messageId: String) {
        let messageReference = FIRDatabase.database().reference().child("messages").child(messageId)
        //then we observe the messages that has those ids under the current user id and append it to a dictionary
        messageReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                //we placed a init constructor in the message model file so we dont have to set it here
                let message = Message(dictionary: dictionary)
                
                //were trying to set up a dictionary of [toId: Messages] with 1 message per toId...working on getting the latest message per Id.
                if let toId = message.toId {
                    self.messagesDictionary[toId] = message
                    
                }
                self.attemptReloadTable()
            }
            
        }, withCancel: nil)

    }
    
    private func attemptReloadTable() {
        //we put a delay on the reloading so reduce the number of time to 1 and get rid of the flickering also the wrong images on cells.
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    //reference to timer so we can invalidate it
    var timer: Timer?
    
    //we put the constructing of array and reloading of table in this method so we can call it in a timer(#selector)
    //reason being, we only wanna do this at the end of all fetching, not everytime it fetches. This saves user battery.
    func handleReloadTable() {
        
        //messages is an array so we convert the messagesDictionary into an array...Confusing? Yes!!!
        self.messages = Array(self.messagesDictionary.values)
        
        //this is how you sort an array, so our tableView are sorted by timestamp in decending order
        self.messages.sort(by: { (message1, message2) -> Bool in
            return (message1.timeStamp?.intValue)! > (message2.timeStamp?.intValue)!
        })
        
        //this will crash because its on background thread, so lets dispatch this to be async with main thread
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
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
    
    //when you select a user you wanna talk to
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else {return}
        
        let ref = FIRDatabase.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            //assingning the chosen user's data into a dictionary variable
            guard let dictionary = snapshot.value as? [String: AnyObject] else {return}
            
            let user = User()
            //setting the id so when we save to firebase it will be set
            user.id = chatPartnerId
            user.setValuesForKeys(dictionary)
            self.showChatControllerForUser(user: user)

        }, withCancel: nil)
        
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
        
        //We call these 4 methods here instead of in viewDidLoad() so that it clears the table and only show what  ObeserveUserMessages returns...
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        obeserveUserMessages()
        
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

