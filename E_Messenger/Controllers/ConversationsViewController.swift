//
//  ViewController.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/10/23.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    private func validateAuth() {
        // use firebase to check if there is an user
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            vc.title = "Login"
            // assign loginViewController as a navigation controller
            let nav = UINavigationController(rootViewController: vc)
            // assign the viewcontroll as a fullscreen not a popup
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

}

