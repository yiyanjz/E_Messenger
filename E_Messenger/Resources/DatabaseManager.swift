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


// MARK: - Sending Messages / Conversations
extension DatabaseManager {
    
    
    /*
     "asdf" {
        "messages": [
            {
                "id": String,
                 "type": text, photo, video,
                 "content": String,
                 "date": Date(),
                 "sender_email": String,
                 "is_read": true/false,
            }
        ]
     }
     
     
     Conversation => [
         [
            [
                "Conversation_id": "asdf"
                "other_user_email":
                "latest_message": => {
                    "date": Date()
                    "latest_message": "message"
                    "is_read": true/false
                }
            ],
         ]
     ]
     */
    
    /// Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail:String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            // for the date
            let messageDate = firstMessage.sentDate
            // this is the static formater call
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            // type of messages
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            // this is under user
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ] as [String : Any]
            ]
            
            // found user then
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversatoin array exists for current user append then
                conversations.append(newConversationData)
                // updated userNode["conversations"] since we append new conversation data
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finshCreatingConversation(conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            } else {
                // create new conversation in user array
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error,_ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finshCreatingConversation(conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finshCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        
        /*
         "asdf" {
            "messages": [
                {
                    "id": String,
                     "type": text, photo, video,
                     "content": String,
                     "date": Date(),
                     "sender_email": String,
                     "is_read": true/false,
                }
            ]
         }
         */
        // for the date
        let messageDate = firstMessage.sentDate
        // this is the static formater call
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        // add to database
        database.child("\(conversationID)").setValue(collectionMessage, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and Returns all Conversation for the user with email
    public func getAllConversations(for email: String, completion: @escaping(Result<String, Error>) -> Void) {
        
    }
    
    /// Get all messages for a given conversation (might need pagination)
    public func getAllMessagesForConversation(with id: String, completion: @escaping(Result<String, Error>) -> Void){
        
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping(Bool) -> Void) {
        
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
