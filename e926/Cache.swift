//
//  Cache.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit

class Cache {
    
    static let shared = Cache()
    private init() { }
    
    lazy var images = Dictionary<String, UIImage>()
    lazy var users = Dictionary<String, UserResult>()
    
    func getImage(withId id: Int, size: ImageResult.Metadata.ImageSize) throws -> UIImage {
        if let image = images["\(size.rawValue)_\(id)"] {
            return image
        } else {
            throw CacheError.noImageInStore(id: id)
        }
    }
    
    func setImage(_ image: UIImage, id: Int, size: ImageResult.Metadata.ImageSize) throws {
        images.updateValue(image, forKey: "\(size.rawValue)_\(id)")
    }
    
    func getUser(withId id: Int) throws -> UserResult {
        if let user = users["\(id)"] {
            return user
        } else {
            throw CacheError.noImageInStore(id: id)
        }
    }
    
    func setUser(_ user: UserResult) throws {
        users.updateValue(user, forKey: "\(user.id)")
    }
    
    enum CacheError: Error {
        case noImageInStore(id: Int)
        case noUserInStore(id: Int)
    }
}
