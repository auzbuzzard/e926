//
//  Result.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

protocol Result {
    
}

protocol ResultListable: Result {
    associatedtype Item: ResultItem
    var results: [Item] { get set }
}
extension ResultListable {
    mutating func add(_ result: [Item]) {
        results.append(contentsOf: result)
    }
    mutating func add(_ result: Self) {
        add(result.results)
    }
}

protocol ResultItem: Result {
    associatedtype Metadata: ResultItemMetadata
    var id: Int { get }
    var metadata: Metadata { get }
}

protocol ResultItemMetadata { }


// Mark: - Actual Classes

struct ListResult: ResultListable {
    var results: [ImageResult]
    var last_before_id: Int? { return results.last?.id }
    
    init() {
        results = [ImageResult]()
    }
    init(result: [ImageResult]) {
        self.init()
        add(result)
    }
    
    mutating func add(_ result: [ImageResult]) {
        results.append(contentsOf: result)
    }
    mutating func add(_ result: ListResult) {
        add(result.results)
    }
}

struct ImageResult: ResultItem, UsingImageCache, UsingTagCache {
    var id: Int { return metadata.id }

    private(set) var metadata: Metadata
    struct Metadata: ResultItemMetadata {
        let id: Int
        let author: String
        
        let tags: String
        var tags_array: [String] { return tags.components(separatedBy: " ")}
        let status: String
        
        let file_url: String
        var file_ext: String?
        var file_ext_enum: File_Ext? {
            return file_ext != nil ? File_Ext(rawValue: file_ext!) : nil
        }
        var file_size: Int?
        
        let width: Int
        let height: Int
        
        let score: Int
        let fav_count: Int
        
        let rating: String
        var rating_enum: Rating {
            return Rating(rawValue: rating) ?? .e //if can't parse, choose e for worst case scenario
        }
        
        let creator_id: Int
        
        let sample_width: Int?
        let sample_height: Int?
        
        let preview_width: Int?
        let preview_height: Int?
        
        var sample_url: String?
        let preview_url: String
        
        let artist: [String]?
        
        enum Status: String {
            case active, flagged, pending, deleted
        }
        enum File_Ext: String {
            case jpg = "jpg", png = "png", gif = "gif", swf = "swf", webm = "webm"
        }
        enum ImageSize: String {
            case file, sample, preview
        }
        enum Rating: String {
            case s = "s", q = "q", e = "e"
        }
        
        func width(ofSize size: ImageSize) -> Int? {
            switch size {
            case .file: return width
            case .sample: return sample_width
            case .preview: return preview_width
            }
        }
        
        func height(ofSize size: ImageSize) -> Int? {
            switch size {
            case .file: return height
            case .sample: return sample_height
            case .preview: return preview_height
            }
        }
    }
    
    func tagResult(from singleTag: String) -> Promise<TagResult> {
        return tagCache.getTag(withName: singleTag)
            .recover { error -> Promise<TagResult> in
                if case TagCache.CacheError.noTagInStore(_) = error {
                    return TagResultRequester().getTag(withName: singleTag)
                } else {
                    throw error
                }
        }
        
    }
    
    func image(ofSize size: Metadata.ImageSize) -> Promise<UIImage> {
        return imageFromCache(size: size)
            .recover { error -> Promise<UIImage> in
                if case ImageCache.CacheError.noImageInStore(_) = error {
                    return self.downloadImage(ofSize: size)
                } else {
                    throw error
                }
        }
    }
    
    func imageFromCache(size: Metadata.ImageSize) -> Promise<UIImage> {
        return imageCache.getImage(withId: self.id, size: size)
    }
    
    func downloadImage(ofSize size: Metadata.ImageSize) -> Promise<UIImage> {
        let url: String = {
            switch size {
            case .file: return metadata.file_url
            case .sample: return metadata.sample_url!
            case .preview: return metadata.preview_url
            }
        }()
        
        return Network.get(url: url)
            .then { data -> Promise<UIImage> in
                guard let image = self.metadata.file_ext_enum == .gif ? UIImage.gif(data: data) : UIImage(data: data) else {
                    throw ImageResultError.dataIsNotUIImage(id: self.id, data: data)
                }
                _ = self.imageCache.setImage(image, id: self.id, size: size)
                return Promise(value: image)
        }
    }
    
    enum ImageResultError: Error {
        case downloadFailed(id: Int, url: String)
        case dataIsNotUIImage(id: Int, data: Data)
    }
}

struct UserResult: ResultItem, UsingUserCache, UsingImageResultCache {
    var id: Int { return metadata.id }

    var metadata: Metadata
    var avatarResult: Promise<ImageResult> { return getAvatarResult() }

    struct Metadata: ResultItemMetadata {
        let name: String
        let id: Int
        let level: Int
        let avatar_id: Int?
    }
    
    func getAvatarResult() -> Promise<ImageResult> {
        guard let avatar_id = metadata.avatar_id else { return Promise<ImageResult>(error: UserResultError.noAvatarId(userId: id)) }
        return imageResultCache.getImageResult(withId: avatar_id)
            .recover { error -> Promise<ImageResult> in
                if case ImageResultCache.CacheError.noImageResultInStore(_) = error {
                    return self.downloadAvatarResult()
                } else { throw error }
        }
    }

     func getAvatar() -> Promise<UIImage> {
        return avatarResult.then { result in
            return result.image(ofSize: .preview)
        }
    }

    private func downloadAvatarResult() -> Promise<ImageResult> {
        guard let avatar_id = metadata.avatar_id else { return Promise<ImageResult>(error: UserResultError.noAvatarId(userId: metadata.id)) }
        return ImageRequester().downloadImageResult(withId: avatar_id)
    }

    enum UserResultError: Error {
        case noAvatarId(userId: Int)
        case avatarIsNotSafe(userId: Int)
    }

}

struct ListCommentResult: ResultListable {
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

