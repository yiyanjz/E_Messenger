//
//  StorageManger.swift
//  E_Messenger
//
//  Created by Justin Zhang on 8/13/23.
//

import Foundation
import FirebaseStorage

final class StorageManger {
    
    static let shared = StorageManger()
    private let storage = Storage.storage().reference()
    
    let metadata = StorageMetadata()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string for downlod
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        
        // how to append data to storage
        storage.child("images/\(fileName)").putData(data, completion: { [weak self] _, error in
            guard let strongSelf = self else {return}
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            // download url
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url return: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        // how to append data to storage
        storage.child("message_images/\(fileName)").putData(data, completion: { [weak self] _, error in
            guard let strongSelf = self else {return}
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            // download url
            strongSelf.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url return: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    /// Upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileurl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        metadata.contentType = "video/quicktime"
        
        // convert video url to data
        if let videoData = NSData(contentsOf: fileurl) as Data? {
            storage.child("message_videos/\(fileName)").putData(videoData, completion: { [weak self] _, error in
                guard let strongSelf = self else {return}
                guard error == nil else {
                    // failed
                    print("failed to upload video file to firebase for video")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                // download url
                strongSelf.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                    guard let url = url else {
                        print("Failed to get download url")
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    let urlString = url.absoluteString
                    print("download url return: \(urlString)")
                    completion(.success(urlString))
                })
            })
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    // downlod the url image from firebase
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        })
    }
}
