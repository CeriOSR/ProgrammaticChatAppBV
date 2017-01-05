//
//  LoginController+Handler.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2017-01-02.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    func handleRegister() {
        //safely unwrapping with guard statement
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text  else {return}
        //registering user into firebase authentication
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error) in
            
            if error != nil {
                
                print(error ?? "")
                
            }
            //safely unwrapping user.uid
            guard let uid = user?.uid else {return}
            //successfully Authenticated user
            //this generates a unique uid and we'll use this as a name for our image so we have a unique name for every image
            let imageName = NSUUID().uuidString
            
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            //unwrapping self.profileImageView.image JPEG to compress from PNG and 0.1 is 10% of original.
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                
                storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil {
                        
                        print(error ?? "")
                        
                    }
                    if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                        
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl]
                        
                        self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String : AnyObject])

                    }
                    
                })
                
            }
        })
        
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
        
        //saving the user into Firebase Database (need a reference to the database
        let ref = FIRDatabase.database().reference(fromURL: "https://chat-app-programmatic.firebaseio.com/")
        //structuring our database
        let usersReference = ref.child("users").child(uid)
        //update the databse
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if err != nil {
                
                print(err ?? "")
                return
                
            }
            //This is to change nav bar title even after registering. using the below to avoid another call/download to firebase
            //use user instead of values but pass values into user class by:
            let user = User()
            user.setValuesForKeys(values)
            self.messagesController?.setupNavBarWithUser(user: user)
            
            self.dismiss(animated: true, completion: nil)
            
        })

        
    }

    
    func handleSelectProfileImageView() {
        
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancelled picker")
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"]{
            
            selectedImageFromPicker = (editedImage as AnyObject) as? UIImage
            
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] {
            
            selectedImageFromPicker = (originalImage as AnyObject) as? UIImage
            
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            profileImageView.image = selectedImage
            
        }
        
        dismiss(animated: true, completion: nil)
    }
}
