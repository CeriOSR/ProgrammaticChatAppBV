//
//  NewMessageController.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-02.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {
    
    let cellId = "cellId"
    
    var users = [User]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
        
    }
    
    func fetchUser() {
        
        let ref = FIRDatabase.database().reference()
        ref.child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let user = User()
                //unique id generated per user, will be used to identify user in conversation
                user.id = snapshot.key
                //app will crash if class properties does not match with snapshot
                user.setValuesForKeys(dictionary)
//                //safer way is
//                user.name = dictionary["name"] as! String?
//                user.email = dictionary["email"] as! String?
                self.users.append(user)
                
                //reload of table has to be done in mainthread but this search is done in the background so to bring it back to main thread..we use this dispatchQueue method
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
            
        }, withCancel: nil)
        
    }
    
    func handleCancel() {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //to use a custom cell class...use .dequeueReuseableCell method
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        if let profileImageUrl = user.profileImageUrl {
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        return cell
    }
    
    //changes height of cells
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    //reference to messages controller so we can call the showChatLogCotroller() from in it
    var messagesController: MessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) { 
            
            let user = self.users[indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user)
        }
    }

}

class UserCell: UITableViewCell {
    
    //changing the constraints of the textLabel and detail textLabel otherwise they'll be covered by custom imageView
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 64, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        
        detailTextLabel?.frame = CGRect(x: 64, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
        
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
        
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        
        //iOS9 constraints x, y, w, h
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
