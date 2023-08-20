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
import JGProgressHUD

class LoginViewController: UIViewController {
    
    // create loading animation
    private let spinner = JGProgressHUD(style: .dark)
    
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
        field.backgroundColor = .secondarySystemBackground
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
        field.backgroundColor = .secondarySystemBackground
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
            
            // save email to userDefaults for google,fb,and normal login
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            // add to database
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                                lastName: lastName,
                                                emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard let user_profile = user.profile else {return}
                            // grab data from google signin
                            if user_profile.hasImage {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                print("grabbed data from google")
                                URLSession.shared.dataTask(with: url, completionHandler: { data, _, _  in
                                    guard let data = data else {return}
                                    print("in url session")
                                    // upload image
                                    let fileName = chatUser.profilePictureFIleName
                                    StorageManger.shared.uploadProfilePicture(with: data, fileName: fileName, completion: {result in
                                        // result here has failure and a success
                                        switch result {
                                        case .success(let downloadUrl):
                                            // save download image to cache for app to use and store it in userDefaults with key profile_picture_url
                                            UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage manger error: \(error)")
                                        }
                                    })
                                }).resume()
                            }
                        }
                    })
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
        
        // present the spinner
        spinner.show(in: view)
        
        // Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            // firebase calls on a background thread, UI needs to be on the main thread
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Error Login User")
                return
            }
            
            // save email to userDefaults for google,fb,and normal login
            UserDefaults.standard.set(email, forKey: "email")
            
            let user = result.user
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String:Any], let firstName = userData["first_name"], let lastName = userData["last_name"] else {
                        return
                    }
                    // save name to userDefaults for google,fb,and normal login
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    
                case .failure(let eroor):
                    print("Failed to read data with :\(eroor)")
                }
            })
            
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
                                                         parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        // getting facebook data
        facebookRequest.start(completion: { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            // print("\(result)") = parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
            
            // decript all information
            guard let firstName = result["first_name"] as? String,
                  let email = result["email"] as? String,
                  let lastName = result["last_name"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from fb result")
                return
            }
            
            // save email to userDefaults for google,fb,and normal login
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            // checks if user exist else add data to database
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                              lastName: lastName,
                                              emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                        if success {
                            guard let url = URL(string: pictureUrl) else {return}
                            
                            print("Downloading data from facebook image")
                            
                            // download bytes from facebook image url
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
                                guard let data = data else {
                                    print("failed to get data from facebook")
                                    return
                                }
                                
                                print("Uploading FB data")
                                // upload image
                                let fileName = chatUser.profilePictureFIleName
                                StorageManger.shared.uploadProfilePicture(with: data, fileName: fileName, completion: {result in
                                    // result here has failure and a success
                                    switch result {
                                    case .success(let downloadUrl):
                                        // save download image to cache for app to use and store it in userDefaults with key profile_picture_url
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manger error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
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
