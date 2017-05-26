//
//  Cache.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

// Mark: Protocols
// For External Class Conformance

protocol UsingImageCache {
    var imageCache: ImageCache { get }
}
extension UsingImageCache {
    var imageCache: ImageCache { return ImageCache.shared }
}
protocol UsingUserCache {
    var userCache: UserCache { get }
}
extension UsingUserCache {
    var userCache: UserCache { return UserCache.shared }
}
protocol UsingImageResultCache {
    var imageResultCache: ImageResultCache { get }
}
extension UsingImageResultCache {
    var imageResultCache: ImageResultCache { return ImageResultCache.shared }
}

// For internal class conformance
protocol CacheClass { }
//extension CacheClass { }

class ImageCache: CacheClass {
    fileprivate static let shared = ImageCache()
    private init() { images.totalCostLimit = 750 * 1024 * 1024 /* 750MB */ }
    
    private lazy var images = NSCache<NSString, UIImage>()
    
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
    
    enum CacheError: Error {
        case noImageInStore(id: Int)
    }
}

class ImageResultCache: CacheClass {
    fileprivate static let shared = ImageResultCache()
    private init() { }
    
    private lazy var results = Dictionary<Int, ImageResult>()
    
    func getImageResult(withId id: Int) -> Promise<ImageResult> {
        return Promise { fulfill, reject in
            if let image = results[id] {
                fulfill(image)
            } else {
                reject(CacheError.noImageResultInStore(id: id))
            }
        }
    }
    
    func setImageResult(_ result: ImageResult) -> Promise<Void> {
        return Promise { fulfill, reject in
            results.updateValue(result, forKey: result.id)
            fulfill()
        }
    }
    
    enum CacheError: Error {
        case noImageResultInStore(id: Int)
    }
}

class UserCache: CacheClass {
    fileprivate static let shared = UserCache()
    private init() { }
    lazy var users = Dictionary<String, UserResult>()
    
    func getUser(withId id: Int) -> Promise<UserResult> {
        return Promise { fulfill, reject in
            if let user = users["\(id)"] {
                fulfill(user)
            } else {
                reject(CacheError.noUserInStore(id: id))
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









