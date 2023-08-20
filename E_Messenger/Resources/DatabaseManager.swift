//
//  DatabaseManager.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/10/23.
//

import Foundation
import FirebaseDatabase
import MessageKit

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

extension DatabaseManager {
    // grab data from database
    public func getDataFor(path: String, completion: @escaping(Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseEroor.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
}

// MARK: - Account Management

extension DatabaseManager {
    
    // @escaping completion will return a value if it is completed else error
    // completion is an error check
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        // observe data and looks for email in database
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
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
    public func createNewConversation(with otherUserEmail:String, otherUserName: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String, let currentName = UserDefaults.standard.value(forKey: "name") else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                "name": otherUserName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ] as [String : Any]
            ]
            // this is for recipient
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ] as [String : Any]
            ]
            // update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue([conversations])

                }else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            // update current user conversation entry
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
                    self?.finshCreatingConversation(otherUserName:otherUserName, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
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
                    self?.finshCreatingConversation(otherUserName:otherUserName, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finshCreatingConversation(otherUserName: String, conversationID: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        
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
            "is_read": false,
            "name": otherUserName
        ]
        
        let messagesValue: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        // add to database
        database.child("\(conversationID)").setValue(messagesValue, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetches and Returns all Conversation for the user with email
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void) {
        // .observe continuious observe but .observesingleevent just observes once
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseEroor.failedToFetch))
                return
            }
            print(value)
            // convert the value format into a dictionary format to call
            let conversation: [Conversation] = value.compactMap({ dictionary in
              guard let conversationsId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        print("cannot get all infor")
                        return nil
              }
                print(conversationsId)
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationsId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            print(conversation)
            completion(.success(conversation))
        })
    }
    
    /// Get all messages for a given conversation (might need pagination)
    public func getAllMessagesForConversation(with id: String, completion: @escaping(Result<[Message], Error>) -> Void){
        // .observe continuious observe but .observesingleevent just observes once
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseEroor.failedToFetch))
                return
            }
            
            // convert the value format into a dictionary format to call
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    print("message info not collected")
                    return nil
                    
                }
                // give message a kind
                var kind: MessageKind?
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus")
                    else {
                        return nil
                    }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo((media))
                }
                else if type == "video" {
                    //video
                    guard let videoUrl = URL(string: content),
                          let placeHolder = UIImage(named: "video_placeholder")
                    else {
                        return nil
                    }
                    let media = Media(url: videoUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else {
                    kind = .text(content)
                }
                
                // unwrap kind and put it in Message()
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            })

            completion(.success(messages))
        })
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversation_p: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping(Bool) -> Void) {
        // add new message to messages
        // update sender latest message (show in chatViewColler the lastest send message)
        // update recipient latest message (show in chatViewColler the lastest send message)
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        database.child("\(conversation_p)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {return}
            guard var currentMessage = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
            case .video(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
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
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            // add new message to messages
            currentMessage.append(newMessageEntry)
            strongSelf.database.child("\(conversation_p)/messages").setValue(currentMessage, withCompletionBlock: { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                // update sender latest message (show in chatViewColler the lastest send message)
                strongSelf.database.child("\(currentSafeEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntyConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    
                    // if user have conversation find the postion where id match
                    // what happens if the collection dont have it (edge case)
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        var targetConversaion: [String: Any]?
                        var position = 0
                        
                        // find wthere id match
                        for conversationDictionary in currentUserConversations {
                            if let currentID = conversationDictionary["id"] as? String, currentID == conversation_p {
                                targetConversaion = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        // check it collections was found
                        // if collection dont have the coversation looking for
                        if var targetConversaion = targetConversaion {
                            targetConversaion["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversaion
                            databaseEntyConversations = currentUserConversations
                        }
                        // append new converasion to collecitono to collection
                        else {
                            let safeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
                            let newConversationData: [String: Any] = [
                                "id": conversation_p,
                                "other_user_email": safeEmail,
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntyConversations = currentUserConversations
                        }
                    }
                    else {
                        // if the user dose not have any conversation
                        let safeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
                        let newConversationData: [String: Any] = [
                            "id": conversation_p,
                            "other_user_email": safeEmail,
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        
                        databaseEntyConversations = [
                            newConversationData
                        ]
                    }
                    
                    // update converstaion
                    strongSelf.database.child("\(currentSafeEmail)/conversations").setValue(databaseEntyConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        // update recipient latest message (show in chatViewColler the lastest send message)
                        // updated the sender side after delting message
                        // here update recipent side
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                            var databaseEntyConversations = [[String: Any]]()
                            
                            // get current user name
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return 
                            }

                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                var targetConversaion: [String: Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentID = conversationDictionary["id"] as? String, currentID == conversation_p {
                                        targetConversaion = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConversaion = targetConversaion {
                                    targetConversaion["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversaion
                                    databaseEntyConversations = otherUserConversations
                                } else {
                                    // failed to find in current collection
                                    let newConversationData: [String: Any] = [
                                        "id": conversation_p,
                                        "other_user_email": currentSafeEmail,
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntyConversations = otherUserConversations
                                }
                                
                            } else {
                                // current collection does not exist
                                let newConversationData: [String: Any] = [
                                    "id": conversation_p,
                                    "other_user_email": currentSafeEmail,
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                
                                databaseEntyConversations = [
                                    newConversationData
                                ]
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntyConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
            })
        })
    }
    
    public func deleteConversation(conversationId: String, completion: @escaping(Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with id: \(conversationId)")
        
        // get all conversations for current user
        // delete coversation in collection with target id
        // reset those conversations for the user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationId {
                        print("found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }
                // delete from database since all data is store in conversations
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("failed to write new conversation array")
                        return
                    }
                    print("deleted conversation")
                    completion(true)
                })
            }
        })
    }
    
    // check if conversation exist if it does return conversationID to open up
    // check coversation after deleting it on either side
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseEroor.failedToFetch))
                return
            }
            
            // iterate and find conversation with target send
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseEroor.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseEroor.failedToFetch))
            return
        })
        
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
