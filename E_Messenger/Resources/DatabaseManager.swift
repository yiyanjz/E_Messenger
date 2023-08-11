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
    public func insertUser(with user: ChatAppUser) {
        // insert to database func
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
    
    private func getSafeEmail(email: String) -> String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
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
}
