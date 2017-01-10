//
//  ChatLogController.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-04.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

//**2 WAYS OF MOVING THE INPUT CONTAINER VIEW VIA MOVING NOTIFICATIONS AND inputAccessoryView...pick one!

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let cellId = "cellId"
    
    //to be called by MessageController.showChatControllerForUser()
    //when set, it will set the ChatLogController nav bar title to the name of the user
    var user: User? {
        
        didSet{
            
            navigationItem.title = user?.name
            
            observeMessages()
            
        }
        
    }
    
    //messages array of type Message to store the messages
    var messages = [Message]()
    
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
        collectionView?.alwaysBounceVertical = true
        //need to register a cell for collectionView
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        //putting some room between the first cell at top and the nav bar, 8 pixels and 50 above the input area and 8 padding between the input and the last bubble
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //have to change the scrollIndicatorInset everytime you change the contentInset to match the scrolling
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        //setupInputComponents()
        
        setupKeyboardObservers()
        
        collectionView?.keyboardDismissMode = .interactive
        
    }
    //lazy var to access self
    //used by inputAccessoryView and canBecomeFirstResponder to make the inputContainer and keyboard interactive by swipes
    lazy var inputContainerView: UIView = {
        
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = .white
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        containerView.addSubview(uploadImageView)
        
        //ios9 constraints x, y, w, h recomended size by apple is 44w44h
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        //type: .system to give the button a downstate
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        containerView.addSubview(self.inputTextField)
        
        //ios9 constraints x, y, w, h
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        //ios9 constraints x, y, w, h
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .lightGray
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        //ios9 constraints x, y, w, h
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        
        return containerView
        
    }()
    
    func handleUploadTap(){
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        //gives us the video folder option in our image picker
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] {
            //we selected a video
            handleVideoSelectedForUrl(url: videoUrl as! NSURL)
            
        } else {
            
            //we selected an image
            handleImageSelectedForInfo(info: info as [String : AnyObject])
        }
        dismiss(animated: true, completion: nil)
    }
    
    //called if we pick a video
    private func handleVideoSelectedForUrl(url: NSURL) {
        
        let filename = NSUUID().uuidString + ".mov" //generates a unique name so we dont overwrite any movies
        //saving the movie into FIRStorage
        let uploadTask = FIRStorage.storage().reference().child("message_movie").child(filename).putFile(url as URL, metadata: nil, completion: { (metadata, error) in
            if error != nil {
                
                print("Could not upload Data:", error ?? "")
            }
            //saving the movie into FIRDatabase
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                //all were missing now is an imageUrl
                if let thumbnailImage = self.thumbnailImageForVideoFileUrl(fileUrl: url) {
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        //imageUrl generated from the method where this closure belongs
                        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height, "videoUrl": videoUrl ]
                        self.sendMessageWithProperties(properties: properties as [String : AnyObject])
                    })
                    
                   

                }
                
            }
        })
        
        //gives the upload status by bytes
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount: Int64 = snapshot.progress?.completedUnitCount {
                
                self.navigationItem.title = String(completedUnitCount)

            }
            print(snapshot.progress?.completedUnitCount ?? "")
        }
        //puts the name back up after success
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }

    }
    //called by handleVideoSelectedForUrl(), this pulls out the first frame as our thumbnail for our video..returns an image OPTIONAL BECAUSE IT COULD RETURN A NIL...needs the Url as parameter not the videoUrl from metadata.
    private func thumbnailImageForVideoFileUrl(fileUrl: NSURL) -> UIImage? {
        let asset = AVAsset(url: fileUrl as URL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage =  try assetImageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)

        } catch let err {
            
            print(err)
        }
        return nil
    }
    
    //called if we pick an image
    private func handleImageSelectedForInfo(info: [String: AnyObject]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"]{
            
            selectedImageFromPicker = (editedImage as AnyObject) as? UIImage
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] {
            
            selectedImageFromPicker = (originalImage as AnyObject) as? UIImage
            
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
            
        }

    }
    
    //gets called imagePickerController() "choose" button, we added a completion block so we can to save us from copy and pasting this method everywhere.
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("messages_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image.", error ?? "")
                    return
                }
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl) //this completion block is added so we dont copy and paste this whole thing for the video thumbnail...REFACTORING!
                }
                
            })
        }
        
    }
    //these 2 vars are needed by the inputAccessoryView so we can interact with textField
    override var inputAccessoryView: UIView? {
        
        get{
            return inputContainerView
        }
        
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    //2 methods needed by collectionViewController
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        //reference to ChatLogController from ChatMessageCell
        cell.chatLogController = self   
        
        //individualizing the members of the array for each cell
        let message = messages[indexPath.item]
        //assigning the value of message here to the message in cell.message
        cell.message = message
        
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        //modifying the bubbleView's width..hide textView in else so its not on top of the image so we can tap it
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameForTex(text: text).width + 32
            cell.textView.isHidden = false
        } else {
            //if image or video fall in here
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }

        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    //cleaning up the cellForItemAt()
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        guard let profileImageUrl = self.user?.profileImageUrl else {return}
        cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        
        //set up both colors in here and else because when cells are reused they may not reset
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            //outgoing message             
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            //playing with the bubbleView anchors to allign it accordingly depending on sender
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            
        }else{
            //incoming message
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            //playing with the bubbleView anchors to allign it accordingly depending on sender
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            
        }
        
        //picks between the imageView or view that displays text if downloaded is either text or image
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
        
    }
    
    //this is called everytime you rotate device or go to landscape mode...this will push the chat to the sides instead of width staying same as the portrait width
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout() //fix we get pretty easily if we use ios9 constraints instead of CGFrames or CGRect
    }
    
    //comforms to UICollectionViewDelegateFlowLayout....extends the cells accross the width with a height of 80
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        //get the estimated height somehow
        let message = messages[indexPath.item]
        if let text = message.text {
            //+20 so the top and bottom dont get cut off...thats how textView works
            height = estimateFrameForTex(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            //h1 / w1 = h2 / w2
            height = CGFloat(imageHeight / imageWidth * 200) //w1 is cell.bubbleWidthAnchor.constant = 200
            
        }
        
        
        //setting the width to this instead of view.frame.width because for some odd reason, inputAccessoryView mucked things up...so this is a sure way of getting the whole width of the device screen.
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    //getting the estimated height of the cells so it expands dependending on how long the text is.
    private func estimateFrameForTex(text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        //ep. 13 9m 02s...basically binding the text in a invisible square around it and thats what we base our cells height and width
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func setupKeyboardObservers() {
        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboarWillHide), name: .UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: .UIKeyboardDidShow , object: nil)
    }
    
    func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
      
    }
    
    func keyboardWillShow(notification: NSNotification) {
        //get the frame of keyboard to figure out where to move the input containerView
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        //get the keyboardDuration so we can animate
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        //after you modify the constraint, to animate just call self.view.layoutIfNeeded()
        containerViewBottomAnchor?.constant = -keyboardFrame.height
        UIView.animate(withDuration: keyboardDuration!) { 
            self.view.layoutIfNeeded()
        }
        
    }
    
    func keyboarWillHide(notification: NSNotification) {
        
        //get the keyboardDuration so we can animate
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        //after you modify the constraint, to animate just call self.view.layoutIfNeeded()
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    //HAVE TO REMOVE ANY NOTIFICATIONS OR ELSE THERE WILL BE A MEMORY LEAK. IDEALLY REMOVE THEM WHEN VIEW DISAPPEARS
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    
    func observeMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else {return}
        //observe all the message id under the current uid in user-messages node first
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            //now we get the messages that has the Id that we fetched above
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in

                //assingning snapshot.value to a dictionary type variable
                guard let dictionary = snapshot.value as? [String: AnyObject] else {return}
                
                self.messages.append(Message(dictionary: dictionary))
                    
                    //bringing back to main thread before calling reloadData else CRASH! cannot reload data in background
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    //scroll to the last index...-1 because array starts at 0
                    let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
    }
    
    //reference to containerView Y constraints
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    //adding the message input components into the view
    func setupInputComponents() {
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        //its default is transparent so you will see the cells behind it. put it to .white to debug it
        containerView.backgroundColor = .white
        
        view.addSubview(containerView)
        
        //ios9 constraints x, y, w, h
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        
        
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
        
        let properties = ["text": inputTextField.text ?? ""] as [String : Any]
        sendMessageWithProperties(properties: properties  as [String: AnyObject])
        inputTextField.text = nil
    }
    
    //gets called by the uploadToFirebaseStorageUsingImage()
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage){
       
        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
       
        sendMessageWithProperties(properties: properties as [String : AnyObject])
    
        
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        
        let ref = FIRDatabase.database().reference().child("messages")
        //generates a child with a unique key in every entry. so we dont replace the previous entries
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()?.currentUser?.uid
        let timeStamp: NSNumber = Int(NSDate().timeIntervalSince1970) as NSNumber
        var values = ["toId": toId, "fromId": fromId ?? "", "timeStamp": timeStamp] as [String : Any]
        
        //append properties dictionary onto values
        //key is $0, value is $1
        properties.forEach({values[$0] = $1})
        
        //restructuring the messages by fanning so we can group them by user id
        //FANNING OUT IS A GREAT COST SAVER BECAUSE YOURE NOT OBSERVING THE WHOLE LIST OF MILLIONS OF MESSAGES BUT ONLY THE ONES WITH THE ITS REFERENCE UNDER THE CURRENT USER ID.
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error!)
            }
            
            //saving a reference to the messages under the current user's id
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId!).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            //saving the same reference to the messages under the recipient's user's id
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId!)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }

        
    }

    
    //use enter to send
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    //references needed for zooming in and zooming out
    var startingFrame: CGRect?
    var blackBackgroundview: UIView?
    var startingImageView: UIImageView?
    
    //custom zoom method using ios9 constraints
    func performZoomInForStartingImageView(startingImageView: UIImageView) {
        
        //hiding the startingImageView once clicked
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundview = UIView(frame: keyWindow.frame)
            blackBackgroundview?.backgroundColor = UIColor.black
            blackBackgroundview?.alpha = 0
            //added before the zoomingImageView so it ends up behind it
            keyWindow.addSubview(blackBackgroundview!)
            keyWindow.addSubview(zoomingImageView)
            
            //animating back out to controller, better animate() can control damping and velocity
            UIView.animate(withDuration: 0.05, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                //animating the blackbackground too
                self.blackBackgroundview!.alpha = 1
                self.inputContainerView.alpha = 0
                
                //ready for some math? we know the (original height: h1) and we know the (original width: w1) we also know (end width: w2). find the h2
                //formula is h1/w1 = h2/w2.......h2 = (h1/w1) * w2
                let height2 = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height2)
                
                zoomingImageView.center = keyWindow.center

                
            }, completion: { (completed: Bool) in
                //do nothing
                
            })

            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                //animating the blackbackground too
                self.blackBackgroundview!.alpha = 1
                self.inputContainerView.alpha = 0
                
                //ready for some math. we know the (original height: h1) and we know the (original width: w1) we also know (end width: w2). find the h2
                //formula is h1/w1 = h2/w2.......h2 = (h1/w1) * w2
                let height2 = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height2)
                
                zoomingImageView.center = keyWindow.center
                
                
            }, completion: nil)

        }
        
    }
    
    func handlZoomOut(tapGesture: UITapGestureRecognizer) {
        //when screen is tapped
        if let zoomOutImageView = tapGesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            //animating back out to controller, better animate() can control damping and velocity
            UIView.animate(withDuration: 0.05, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundview?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (completed: Bool) in
                //completely remove traces of zoomOutImageView
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
}
