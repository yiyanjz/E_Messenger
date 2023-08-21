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
import SDWebImage

// 2 types profileViewModel will have
enum ProfileViewModelType {
    case info, logout
}

// create a struct instead of data = ["logout"\
struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register tableview
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        // add cells for profile
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler: nil))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")" , handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Logout", handler: { [weak self] in
            guard let strongSelf = self else {return}
            let actionSheet = UIAlertController(title: "",
                                                message: "",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Logout",
                                                style: .destructive,
                                                handler: { _ in
                
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
            
            strongSelf.present(actionSheet, animated: true)
        }))
        
        // register for identifer
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        // interactions
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        // grab email from userDefaults
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }

        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = safeEmail + "_profile_picture.png"
        let path = "images/" + filename

        let headerView = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: self.view.width,
                                        height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150)/2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        // download image url
        StorageManger.shared.downloadURL(for: path, completion: { result in
            switch result{
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        })

        return headerView
    }

// whole function can be replaced with imageView.sd_setImage(with: url, completed: nil)
//    func downloadImage(imageView: UIImageView, url: URL) {
//        // same as the code below
//
//        // this URLSession downloads data from that url
//        URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
//            guard let data = data, error == nil else {
//                return
//            }
//
//            // anything in UI should be on main thread
//            DispatchQueue.main.async {
//                let image = UIImage(data: data)
//                imageView.image = image
//            }
//        }).resume()
//    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // after using as! we have access to that class
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        // then we can call
        let viewModel =  data[indexPath.row]
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // if it has a handler then it can call the hanlder
        data[indexPath.row].handler?()
    }
}


// present the cell in simulator
class ProfileTableViewCell: UITableViewCell {
    
    // create an idenifer to connect
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title

        switch viewModel.viewModelType {
        case .info:
            self.textLabel?.textAlignment = .left
            // to make it unselectebale
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}
