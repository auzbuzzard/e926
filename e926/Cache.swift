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
    private init() {
        images.totalCostLimit = 750 * 1024 * 1024 // 750MB
    }
    
    lazy var images = NSCache<NSString, UIImage>()
    private lazy var imagesOrder = Dictionary<Int, String>()
    lazy var users = Dictionary<String, UserResult>()
    
    func getImage(withId id: Int, size: ImageResult.Metadata.ImageSize) -> Promise<UIImage> {
        return Promise { fulfill, reject in
            if let image = images.object(forKey: "\(id)_\(size.rawValue)" as NSString) {
                fulfill(image)
            } else {
                reject(CacheError.noImageInStore(id: id))
            }
        }
    }
    
    func setImage(_ image: UIImage, id: Int, size: ImageResult.Metadata.ImageSize) -> Promise<Void> {
        return Promise { fulfill, reject in
            let cost = UIImageJPEGRepresentation(image, 1.0)?.count
            images.setObject(image, forKey: "\(id)_\(size.rawValue)" as NSString, cost: cost ?? 0)
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

fileprivate class CacheObject<T> {
    var object:T
    var timestamp: Date
    var name: String
    
    init(name: String, object:T) {
        self.name = name
        self.object = object
        timestamp = Date()
    }
}









