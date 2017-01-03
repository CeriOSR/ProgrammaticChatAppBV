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
            
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).png")
            
            //need to unwrap this variable
            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
                
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
