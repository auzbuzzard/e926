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
    var last_before_id: Int? = nil
    
    init() {
        results = [ImageResult]()
    }
    init(result: [ImageResult]) {
        self.init()
        add(result)
    }
    
    mutating func add(_ result: [ImageResult]) {
        results.append(contentsOf: result)
        last_before_id = results.last?.id
    }
    mutating func add(_ result: ListResult) {
        add(result.results)
    }
}

struct ImageResult: ResultItem, UsingImageCache {
    var id: Int { return metadata.id }

    private(set) var metadata: Metadata
    struct Metadata: ResultItemMetadata {
        let id: Int
        let author: String
        
        let tags: String
        
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
        var rating_enum: Rating? {
            return Rating(rawValue: rating)
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







//class ListResult: ResultListable {
//
//    var results = [ImageResult]()
//    var last_before_id: Int?
//
//    convenience init(result: [ImageResult]) {
//        self.init()
//        add(result)
//    }
//
//    func add(_ result: [ImageResult]) {
//        results.append(contentsOf: result)
//        last_before_id = results.last?.id
//    }
//    func add(_ result: ListResult) {
//        add(result.results)
//    }
//    
//}
//
//class ImageResult: ResultItem {
//    
//    var id: Int { return metadata.id }
//    
//    var metadata: Metadata {
//        didSet {
//            downloadImage(ofSize: .preview).catch { error in }
//        }
//    }
//    
//    var creator: UserResult?
//    
//    struct Metadata: ResultItemMetadata {
//        let id: Int
//        let author: String
//        
//        let tags: String
//        
//        let status: String
//        
//        let file_url: String
//        var file_ext: String?
//        var file_ext_enum: File_Ext? {
//            return file_ext != nil ? File_Ext(rawValue: file_ext!) : nil
//        }
//        var file_size: Int?
//        
//        let width: Int
//        let height: Int
//        
//        let score: Int
//        let fav_count: Int
//        
//        let rating: String
//        var rating_enum: Rating? {
//            return Rating(rawValue: rating)
//        }
//        
//        let creator_id: Int
//        
//        let sample_width: Int?
//        let sample_height: Int?
//        
//        let preview_width: Int?
//        let preview_height: Int?
//        
//        var sample_url: String?
//        let preview_url: String
//        
//        let artist: [String]?
//        
//        enum Status: String {
//            case active, flagged, pending, deleted
//        }
//        enum File_Ext: String {
//            case jpg = "jpg", png = "png", gif = "gif", swf = "swf", webm = "webm"
//        }
//        enum ImageSize: String {
//            case file, sample, preview
//        }
//        enum Rating: String {
//            case s = "s", q = "q", e = "e"
//        }
//        
//        func width(ofSize size: ImageSize) -> Int? {
//            switch size {
//            case .file: return width
//            case .sample: return sample_width
//            case .preview: return preview_width
//            }
//        }
//        
//        func height(ofSize size: ImageSize) -> Int? {
//            switch size {
//            case .file: return height
//            case .sample: return sample_height
//            case .preview: return preview_height
//            }
//        }
//    }
//    
//    init(metadata: Metadata) {
//        self.metadata = metadata
//    }
//    
//    func image(ofSize size: Metadata.ImageSize) -> Promise<UIImage> {
//        return imageFromCache(size: size)
//            .recover { error -> Promise<UIImage> in
//                if case Cache.CacheError.noImageInStore(_) = error {
//                    return self.downloadImage(ofSize: size)
//                } else {
//                    throw error
//                }
//            }
//    }
//    
//    func imageFromCache(size: Metadata.ImageSize) -> Promise<UIImage> {
//        return Cache.shared.getImage(withId: self.id, size: size)
//    }
//    
//    func downloadImage(ofSize size: Metadata.ImageSize) -> Promise<UIImage> {
//        var url = ""
//        switch size {
//        case .file: url = metadata.file_url
//        case .sample: url = metadata.sample_url!
//        case .preview: url = metadata.preview_url
//        }
//        
//        return Network.get(url: url)
//            .then { data -> Promise<UIImage> in
//                guard let image = self.metadata.file_ext_enum == .gif ? UIImage.gif(data: data) : UIImage(data: data) else {
//                    throw ImageResultError.dataIsNotUIImage(id: self.id, data: data)
//                }
//                _ = Cache.shared.setImage(image, id: self.id, size: size)
//                return Promise(value: image)
//        }
//    }
//    
//    enum ImageResultError: Error {
//        case downloadFailed(id: Int, url: String)
//        case dataIsNotUIImage(id: Int, data: Data)
//    }
//}
//
//class UserResult: ResultItem {
//    
//    var id: Int { return metadata.id }
//    
//    var metadata: Metadata
//    var avatarImageResult: ImageResult?
//    
//    struct Metadata: ResultItemMetadata {
//        let name: String
//        let id: Int
//        let level: Int
//        let avatar_id: Int?
//    }
//    
//    init(metadata: Metadata) {
//        self.metadata = metadata
//    }
//    
//    func getAvatar() -> Promise<UIImage> {
//        if let imageResult = avatarImageResult {
//            return imageResult.image(ofSize: .preview)
//        } else {
//            return downloadAvatarResult().then { result -> Promise<UIImage> in
//                return result.image(ofSize: .preview)
//            }
//        }
//    }
//    
//    func avatarFromCache() -> Promise<UIImage> {
//        if let imageResult = avatarImageResult {
//            return imageResult.imageFromCache(size: .preview)
//        } else {
//            return downloadAvatarResult().then { result in
//                return result.imageFromCache(size: .preview)
//            }
//        }
//    }
//    
//    private func downloadAvatarResult() -> Promise<ImageResult> {
//        guard let avatar_id = metadata.avatar_id else { return Promise<ImageResult>(error: UserResultError.noAvatarId(userId: metadata.id)) }
//        return ImageRequester().downloadImageResult(withId: avatar_id).then { result -> ImageResult in
//            self.avatarImageResult = result
//            return result
//        }
//    }
//    
//    enum UserResultError: Error {
//        case noAvatarId(userId: Int)
//        case avatarIsNotSafe(userId: Int)
//    }
//    
//}
//
//
//



