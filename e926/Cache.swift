//
//  Cache.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

class Cache {
    
    static let shared = Cache()
    private init() { }
    
    lazy var images = Dictionary<String, UIImage>()
    lazy var users = Dictionary<String, UserResult>()
    
    func getImage(withId id: Int, size: ImageResult.Metadata.ImageSize) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            if let image = images["\(size.rawValue)_\(id)"] {
                fulfill(image)
            } else {
                reject(CacheError.noImageInStore(id: id))
            }
        }
    }
    
    func setImage(_ image: UIImage, id: Int, size: ImageResult.Metadata.ImageSize) -> Promise<Void> {
        return Promise { fulfill, reject in
            images.updateValue(image, forKey: "\(size.rawValue)_\(id)")
            fulfill()
        }
    }
    
    func getUser(withId id: Int) -> Promise<UserResult> {
        return Promise { fulfill, reject in
            if let user = users["\(id)"] {
                fulfill(user)
            } else {
                reject(CacheError.noImageInStore(id: id))
            }
        }
    }
    
    func setUser(_ user: UserResult) -> Promise<Void> {
        return Promise { fulfill, reject in
            users.updateValue(user, forKey: "\(user.id)")
            fulfill()
        }
    }
    
    enum CacheError: Error {
        case noImageInStore(id: Int)
        case noUserInStore(id: Int)
    }
}
