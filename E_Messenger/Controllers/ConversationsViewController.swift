//
//  ViewController.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/10/23.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // stores isLogginIn value into system default with a key called "logged_in"
        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        
        // check for login state
        if !isLoggedIn {
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

