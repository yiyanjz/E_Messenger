//
//  DatabaseManager.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/10/23.
//

import Foundation
import FirebaseDatabase

// this class cannot be subclass
final class DatabaseManager {
    
    // only belong to this class (static)
    // so when calling this class it will be DatabaseManager.shared.insertUser instead of creating a var = DatabaseManager()
    static let shared = DatabaseManager()
    // reference to Firebase database
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}


// MARK: - Account Management

extension DatabaseManager {
    
    // @escaping completion will return a value if it is completed else error
    // completion is an error check
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = getSafeEmail(email: email)
                
        // observe data and looks for email in database
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            // complete return true
            completion(true)
        })
    }
    
    /// inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        // insert to database func
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            /*
             users => [
                 [
                    [
                        "name":
                        "safe_email":
                    ],
                 ]
             ]
             */
            
            // get all users in one request from firebase (save databse cost)
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // apppend to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                        completion(true)
                    })
                } else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                        completion(true)
                    })
                }
            })
        })
    }
    private func getSafeEmail(email: String) -> String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    // grab all users when request to firebase
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseEroor.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    // an extension case error for Error
    public enum DatabaseEroor: Error {
        case failedToFetch
    }
}

// wrap all values want to insert
struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFIleName: String {
        //justinzhang321-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
