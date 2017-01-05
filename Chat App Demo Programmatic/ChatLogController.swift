//
//  ChatLogController.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-04.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate {
    
    //to be called by MessageController.showChatControllerForUser()
    //when set, it will set the ChatLogController nav bar title to the name of the user
    var user: User? {
        
        didSet{
            
            navigationItem.title = user?.name
        }
        
    }
    
    lazy var inputTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Message..."
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        return tf
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white
        
        setupInputComponents()
        
    }
    
    //adding the message input components into the view
    func setupInputComponents() {
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        //ios9 constraints x, y, w, h
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //type: .system to give the button a downstate
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        containerView.addSubview(inputTextField)
        
        //ios9 constraints x, y, w, h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        //ios9 constraints x, y, w, h
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .lightGray
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        //ios9 constraints x, y, w, h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }
    
    func handleSend() {
        
        let ref = FIRDatabase.database().reference().child("messages")
        //generates a child with a unique key in every entry. so we dont replace the previous entries
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()?.currentUser?.uid
        let timeStamp: NSNumber = Int(NSDate().timeIntervalSince1970) as NSNumber
        let values = ["text": inputTextField.text ?? "", "toId": toId, "fromId": fromId ?? "", "timeStamp": timeStamp] as [String : Any]
        childRef.updateChildValues(values)
        
        inputTextField.text = nil
    }
    
    //use enter to send
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
}
