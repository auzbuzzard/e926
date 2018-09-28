//
//  Result.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

protocol ModelResult {
    
}

protocol ResultListable: ModelResult {
    associatedtype Item: ResultItem
    var results: [Item] { get set }
}
extension ResultListable {
    var last_before_id: Int? { return results.last?.id }
    
    mutating func add(_ result: [Item]) {
        results.append(contentsOf: result)
    }
    mutating func add(_ result: Self) {
        add(result.results)
    }
}

protocol ResultItem: ModelResult {
    associatedtype Metadata: ResultItemMetadata
    var id: Int { get }
    var metadata: Metadata { get }
}

protocol ResultItemMetadata { }


// Mark: - Actual Classes

struct ListResult: ResultListable {
    typealias ResultType = ImageResult
    
    var results: [ResultType]
    private(set) var currentPage = 0
    var tags: [String]?
    var tagsAsString: String? { return tags?.joined(separator: " ") }
    
    init() {
        results = [ResultType]()
    }
    init(result: [ResultType]) {
        self.init()
        add(result)
    }
    
    mutating func add(_ result: [ResultType]) {
        results.append(contentsOf: result)
        currentPage += 1
    }
    mutating func add(_ result: ListResult) {
        add(result.results)
    }
}



struct UserResult: ResultItem {
    var id: Int { return metadata.id }

    var metadata: Metadata
    var avatarResult: Promise<ImageResult> {
        guard let avatar_id = metadata.avatar_id else { return Promise<ImageResult>(error: Errors.noAvatarId(userId: id)) }
        return Cache.imageResult.getImageResult(withId: avatar_id)
        .recover { error -> Promise<ImageResult> in
            if case ImageResultCache.CacheError.noImageResultInStore(_) = error {
                return ImageRequester().downloadImageResult(withId: avatar_id)
            } else { throw error }
        }
    }

    struct Metadata: ResultItemMetadata {
        let name: String
        let id: Int
        let level: Int
        let avatar_id: Int?
    }
    
    static func getUser(by id: Int) -> Promise<UserResult> {
        return Cache.user.getUser(withId: id)
        .recover { error -> Promise<UserResult> in
            switch error {
            case UserCache.CacheError.noUserInStore(_):
                return UserRequester().getUser(WithId: id)
            default: throw error
            }
        }
    }

     func getAvatar() -> Promise<Data> {
        return avatarResult.then { result in
            return result.imageData(for: .preview)
        }
    }

    enum Errors: Error {
        case noAvatarId(userId: Int)
        case avatarIsNotSafe(userId: Int)
    }

}

struct CommentListResult: ResultListable {
    var results: [CommentResult]
    
    init() {
        results = [CommentResult]()
    }
    init(result: [CommentResult]) {
        self.init()
        add(result)
    }
}

struct CommentResult: ResultItem {
    var id: Int { return metadata.id }
    var metadata: Metadata
    
    struct Metadata: ResultItemMetadata {
        let id: Int
        let created_at: String
        let post_id: Int
        let creator: String
        let creator_id: Int
        let body: String
        let score: Int
    }
}

struct TagResult: ResultItem {
    var id: Int { return metadata.id }
    var metadata: Metadata
    
    struct Metadata: ResultItemMetadata {
        let id: Int
        let name: String
        let count: Int
        let type: Int
        var type_enum: TypeEnum { return TypeEnum(rawValue: type) ?? .general }
        enum TypeEnum: Int {
            case general = 0, artist = 1, copyright = 3, character = 4, species = 5
        }
    }
}

struct PoolResult: ResultItem, ResultListable {
    var results: [ImageResult] { get { return metadata.posts } set { metadata.posts = newValue } }
    
    var id: Int { return metadata.id }
    var metadata: Metadata
    
    struct Metadata: ResultItemMetadata {
        let created_at: (json_class: String, s: Int, n: Int)
        let description: String
        let id: Int
        let is_active: Bool
        let is_locked: Bool
        let name: String
        let post_count: Int
        let updated_at: (json_class: String, s: Int, n: Int)
        let user_id: Int
        
        var posts: [ImageResult]
    }
    
    mutating func add(_ result: [ImageResult]) {
        results.append(contentsOf: result)
    }
    mutating func add(_ result: PoolResult) {
        add(result.results)
    }
}






