//
//  LoginViewController.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/10/23.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import Firebase

class LoginViewController: UIViewController {
    
    // Create UIViews
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollview = UIScrollView()
        scrollview.clipsToBounds = true
        return scrollview
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Adress.."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password.."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    // Create Buttons
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        return button
    }()
    
    private let googleLoginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Continue with Google", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // create a notifaction observer
        // call this NotificationCenter.default.post(name:.didLogInNotification, object:nil)
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {return}
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)

        })
        
        // create a button on the right side
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        // add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)

        // add action for login button
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        // google button give an action
        googleLoginButton.addTarget(self,
                                    action: #selector(googleButtonTapped),
                                    for: .touchUpInside)
        
        // delegates (transaction to view or controller)
        // example) emailfield hit enter goes to passwordfield hit enter again loginbutton tapped
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        
        // facebok/google login button center after creating a UIButton
        facebookLoginButton.center = view.center
        googleLoginButton.center = view.center
    }
    
    // get rid of observation if called (get rid of memory)
    deinit{
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // give frame for views
        scrollView.frame = view.bounds
        let size = view.width/3
        imageView.frame = CGRect(x: (view.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                  y: emailField.bottom + 10,
                                  width: scrollView.width-60,
                                  height: 52)
        loginButton.frame = CGRect(x: 30,
                                  y: passwordField.bottom + 10,
                                  width: scrollView.width-60,
                                  height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                  y: loginButton.bottom + 20,
                                  width: scrollView.width-60,
                                  height: 52)
        googleLoginButton.frame = CGRect(x: 30,
                                  y: facebookLoginButton.bottom + 20,
                                  width: scrollView.width-60,
                                  height: 52)
    }
    
    @objc private func googleButtonTapped() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self)
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("no clientID found")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self){ [weak self] result, error in
            guard let strongSelf = self else {
                return
            }
                        
            guard let user = result?.user else {return}
            guard let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName,
                  let email = user.profile?.email,
                  let idToken = user.idToken?.tokenString else {
                    return
            }
            // add to database
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                        lastName: lastName,
                                                                        emailAddress: email))
                }
            })
            // grab credential for firbase login from google
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            // firebase login
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {authResult, error in
                guard authResult != nil, error == nil else {
                    print("failed to log in with google credentials")
                    return
                }
                print("loggined into app")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        // push to next ViewController for NaviagtionController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        // dismiss keyboard
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        // Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            guard let result = authResult, error == nil else {
                print("Error Login User")
                return
            }
            
            let user = result.user
            print("User: \(user) Logged In")
            
            // dismiss controller after sign in
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Enter All Information", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
}

// extension for delegate for text
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

// extension for delegate for facebook login button
extension LoginViewController: LoginButtonDelegate {
    // this functions updates the text on facebook login button (not need for this project)
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to login with facebook")
            return
        }
        
        // get data from facebook login
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        // getting facebook data
        facebookRequest.start(completion: { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            // print("\(result)") ["email": justinzhang321@gmail.com, "name": Justin Zhang, "id": 9524516827618643]
            
            // decript first and last name
            guard let userName = result["name"] as? String, let email = result["email"] as? String else {
                print("Failed to get email and name from fb result")
                return
            }
            
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else {
                return
            }
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            // checks if user exist else add data to database
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                        lastName: lastName,
                                                                        emailAddress: email))
                }
            })
            
            // trade token to firebase to get a credential
            let credentital = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credentital, completion: { [weak self] authResult, error in
                guard let Strongself = self else {return}
                guard authResult != nil, error == nil else {
                    // MFA (two factor auth)
                    print("Facebook credential login failed, MFA may be needed")
                    return
                }
                Strongself.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
}
