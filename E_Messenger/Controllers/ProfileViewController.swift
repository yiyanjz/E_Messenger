//
//  ProfileViewController.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/10/23.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Logout"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // register for identifer
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        // interactions
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "",
                                            message: "",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Logout",
                                            style: .destructive,
                                            handler: { [weak self] _ in
            guard let strongSelf = self else {return}
            
            // Log out facebook
            FBSDKLoginKit.LoginManager().logOut()
            
            // Log out google
            GIDSignIn.sharedInstance.signOut()
            
            // log out firebase
            do {
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
            }catch {
                print("Failed to log out")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
}
