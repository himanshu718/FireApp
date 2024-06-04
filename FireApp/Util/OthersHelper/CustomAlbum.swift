//
//  CustomAlbum.swift
//  TestingSaveImageMania
//
//  Created by Alex Nagy on 14/04/2019.
//  Copyright © 2019 Alex Nagy. All rights reserved.
//

import Photos
import UIKit

struct CustomAlbumError {
    static let notAuthorized = CustomError(title: "Custom Album Error", description: "Not Authorized", code: 0)
}
typealias CustomAlbumClosure =  (Result<Bool, Error>) -> ()
class CustomAlbum: NSObject {
    var name = "Custom Album"
//    static let shared = CustomAlbum()
    
    private var assetCollection: PHAssetCollection!
    
    init(name: String) {
        self.name = name
        super.init()
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
    }
    
    func checkAuthorizationWithHandler(completion: @escaping (Result<Bool, Error>) -> ()) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ (status) in
                self.checkAuthorizationWithHandler(completion: completion)
            })
        }
        else if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.createAlbumIfNeeded { (success) in
                completion(success)
            }
        }
        else {
            completion(.failure(CustomAlbumError.notAuthorized))
        }
    }
    
    private func createAlbumIfNeeded(completion: @escaping (Result<Bool, Error>) -> ()) {
        if let assetCollection = fetchAssetCollectionForAlbum() {
            // Album already exists
            self.assetCollection = assetCollection
            completion(.success(true))
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.name)   // create an asset collection with the album name
            }) { success, error in
                if let error = error {
                    completion(.failure(error))
                }
                if success {
                    self.assetCollection = self.fetchAssetCollectionForAlbum()
                    completion(.success(true))
                } else {
                    // Unable to create album
                    completion(.success(false))
                }
            }
        }
    }
    
    private func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    
    func save(image: UIImage, _ completion: CustomAlbumClosure?) {
        self.checkAuthorizationWithHandler { (result) in
            switch result {
            case .success(let success):
                
                if success, self.assetCollection != nil {
                    PHPhotoLibrary.shared().performChanges({
                        let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)

                        let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                        if let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection) {
                            let enumeration: NSArray = [assetPlaceHolder!]
                            albumChangeRequest.addAssets(enumeration)
                        }
                        
                    }, completionHandler: { (success, error) in
                        if let error = error {
                            completion?(.failure(error))
                            return
                        }
                        completion?(.success(success))
                    })
                    
                }
                
            case .failure(let err):
                completion?(.failure(err))
            }
        }
        
    }
    
    func save(videoUrl:URL, _ completion: CustomAlbumClosure?) {
        self.checkAuthorizationWithHandler { (result) in
            switch result {
            case .success(let success):
                
                if success, self.assetCollection != nil {
                    PHPhotoLibrary.shared().performChanges({
                        let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                        let assetPlaceHolder = assetChangeRequest?.placeholderForCreatedAsset
                        if let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection) {
                            let enumeration: NSArray = [assetPlaceHolder!]
                            albumChangeRequest.addAssets(enumeration)
                        }
                        
                    }, completionHandler: { (success, error) in
                        if let error = error {
                            completion?(.failure(error))
                            return
                        }
                        completion?(.success(success))
                    })
                    
                }
                
            case .failure(let err):
                completion?(.failure(err))
            }
        }
        
    }
    
  
    
}

protocol OurErrorProtocol: LocalizedError {
    var title: String? { get }
    var code: Int { get }
}

struct CustomError: OurErrorProtocol {
    
    var title: String?
    var code: Int
    var errorDescription: String? { return _description }
    var failureReason: String? { return _description }
    
    private var _description: String
    
    init(title: String?, description: String, code: Int) {
        self.title = title ?? "Error"
        self._description = description
        self.code = code
    }
}

