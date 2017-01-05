//
//  LoginController.swift
//  Chat App Demo Programmatic
//
//  Created by Rey Cerio on 2016-12-31.
//  Copyright © 2016 CeriOS. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {
    
    //cannot add a property in extension is the reason we declaring this here but using it in extension
    var messagesController: MessagesController?
    
    //input container
    let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        //activates the constraints when .isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        //rounding the corners...needs masksToBounds = true
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    //login button
    lazy var loginRegisterButton: UIButton = {
        //type: .system so it has a downstate when pressed
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Register", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        
        return button
    }()
    
    func handleLoginRegister(){
        
        if loginRegisterSegmentedController.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
        
    }
    
    func handleLogin(){
        
        //safely unwrapping with guard statement
        guard let email = emailTextField.text, let password = passwordTextField.text else {return}
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            if error != nil {
                print(error ?? "")
                return
            }
            //logged in the user to firebase. calling fetchUserAndSetupNavBarTitle() will change the nav bar title appropriately
            self.messagesController?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
            
        })
        
    }
    
    let nameTextField: UITextField = {
        
        let text = UITextField()
        text.placeholder = "Name"
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
        
    }()
    
    let nameSeparatorView: UIView = {
        
       let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
        
    }()
    
    let emailTextField: UITextField = {
        
        let text = UITextField()
        text.placeholder = "Email"
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
        
    }()
    
    let emailSeparatorView: UIView = {
        
        let view = UIView()
        view.backgroundColor = UIColor(r: 220, g: 220, b: 220)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
        
    }()
    
    let passwordTextField: UITextField = {
        
        let text = UITextField()
        text.placeholder = "Password"
        text.translatesAutoresizingMaskIntoConstraints = false
        text.isSecureTextEntry = true
        return text
        
    }()
    
    lazy var profileImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "kestrel")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        //adding a tap gesture recognizer. also setting user interaction to true because its default at false
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        
        return imageView
        
    }()
    
    //lazy var so you have access to self
    lazy var loginRegisterSegmentedController: UISegmentedControl = {
        
       let sc = UISegmentedControl(items: ["Login", "Register"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.tintColor = UIColor.white
        sc.selectedSegmentIndex = 1
        sc.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return sc
        
    }()
    
    func handleLoginRegisterChange() {
        
        let title = loginRegisterSegmentedController.titleForSegment(at: loginRegisterSegmentedController.selectedSegmentIndex)
        loginRegisterButton.setTitle(title, for: .normal)
        
        
        
        //change height of input container view
        //short style of If Statement
        inputContainerViewHeightAnchor?.constant = loginRegisterSegmentedController.selectedSegmentIndex == 0 ? 100 : 150
        
        //change height of nameTextField
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: loginRegisterSegmentedController.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        nameTextField.placeholder = loginRegisterSegmentedController.selectedSegmentIndex == 0 ? "" : "Name"
        
        //change height of emailTextField
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: loginRegisterSegmentedController.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        //change height of passwordTextField
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: loginRegisterSegmentedController.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true


        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        view.addSubview(inputContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedController)
        
        setupInputContainerView()
        setupLoginRegisterButton()
        setupProfileImageView()
        setupLoginRegisterSegmentedControl()
        
    }
    
    func setupProfileImageView() {
        
        //x, y, width, height: ProfileImageView
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedController.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
    }
    
    func setupLoginRegisterSegmentedControl(){
        
        loginRegisterSegmentedController.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterSegmentedController.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedController.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        loginRegisterSegmentedController.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    //need a reference for height to change according to segmentControl selected index
    var inputContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    func setupInputContainerView() {
        
        //ios9 constraints x,y,width,height
        inputContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        //need a reference for height to change according to segmentControl selected index
        inputContainerViewHeightAnchor = inputContainerView.heightAnchor.constraint(equalToConstant: 150)
        inputContainerViewHeightAnchor?.isActive = true
        
        inputContainerView.addSubview(nameTextField)
        inputContainerView.addSubview(nameSeparatorView)
        inputContainerView.addSubview(emailTextField)
        inputContainerView.addSubview(emailSeparatorView)
        inputContainerView.addSubview(passwordTextField)
        
        //ios9 constraints x,y,width,height Name Text Field
        nameTextField.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        //reference to be changed according to segmented control selected index
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        //ios9 constraints x,y,width,height Name Separator Line
        nameSeparatorView.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor).isActive = true
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive =  true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        //ios9 constraints x,y,width,height Email Text Field
        emailTextField.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        emailTextFieldHeightAnchor =  emailTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        
        //ios9 constraints x,y,width,height Email Separator Line
        emailSeparatorView.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor).isActive = true
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive =  true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        
        //ios9 constraints x,y,width,height Password Text Field
        passwordTextField.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
    }
    
    func setupLoginRegisterButton() {
        
        //ios9, x, y, width, height
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    
    //this is now a property not a method. override func will throw an error
    //this property makes the status bar at the top into white instead of dark
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return .lightContent
        
    }


}

//convenience constructor so we only have to type the numerator
extension UIColor {
    
    
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
        
    }
}
