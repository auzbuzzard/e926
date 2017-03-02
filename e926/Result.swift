//
//  Result.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

class Result {
    
}

class ListResult: Result {
    
    lazy var results = [ImageResult]()
    var last_before_id: Int?
    
    convenience init(result: [ImageResult]) {
        self.init()
        add(result)
    }
    
    func add(_ result: [ImageResult]) {
        results.append(contentsOf: result)
        last_before_id = results.last?.id
    }
    func add(_ result: ListResult) {
        add(result.results)
    }
    
}

class ImageResult: Result {
    
    var id: Int { return metadata.id }
    
    var metadata: Metadata {
        didSet {
            downloadImage(ofSize: .preview).catch { error in }
        }
    }
    
    var creator: UserResult?
    
    struct Metadata {
        let id: Int
        let author: String
        
        let tags: String
        
        let status: String
        
        let file_url: String
        var file_ext: String?
        var file_size: Int?
        
        let width: Int
        let height: Int
        
        let score: Int
        let fav_count: Int
        
        let rating: String
        var rating_enum: Rating? {
            switch rating {
            case "s": return Rating.s
            case "q": return Rating.q
            case "e": return Rating.e
            default: return nil
            }
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
            case jpg, png, gif, swf, webm
        }
        enum ImageSize: String {
            case file, sample, preview
        }
        enum Rating: String {
            case s, q, e
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
    
    init(metadata: Metadata) {
        self.metadata = metadata
    }
    
    func image(ofSize size: Metadata.ImageSize) -> Promise<UIImage> {
        return imageFromCache(size: size)
            .recover { error -> Promise<UIImage> in
                if case Cache.CacheError.noImageInStore(_) = error {
                    return self.downloadImage(ofSize: size)
                } else {
                    throw error
                }
            }
    }
    
    func imageFromCache(size: Metadata.ImageSize) -> Promise<UIImage> {
        return Cache.shared.getImage(withId: self.id, size: size)
    }
    
    func downloadImage(ofSize size: Metadata.ImageSize) -> Promise<UIImage> {
        var url = ""
        switch size {
        case .file: url = metadata.file_url
        case .sample: url = metadata.sample_url!
        case .preview: url = metadata.preview_url
        }
        
        return Network.get(url: url)
            .then { data -> Promise<UIImage> in
                return Promise { fulfill, reject in
                    if let image = UIImage(data: data) {
                        _ = Cache.shared.setImage(image, id: self.id, size: size)
                        fulfill(image)
                    } else {
                        reject(ImageResultError.dataIsNotUIImage(id: self.id, data: data))
                    }
                }
        }
    }
    
    enum ImageResultError: Error {
        case downloadFailed(id: Int, url: String)
        case dataIsNotUIImage(id: Int, data: Data)
    }
}

class UserResult: Result {
    
    var id: Int { return metadata.id }
    
    var metadata: Metadata
    var avatarImageResult: ImageResult?
    
    struct Metadata {
        let name: String
        let id: Int
        let level: Int
        let avatar_id: Int?
    }
    
    init(metadata: Metadata) {
        self.metadata = metadata
    }
    
    func getAvatar() -> Promise<UIImage> {
        if let imageResult = avatarImageResult {
            return imageResult.image(ofSize: .preview)
        } else {
            return downloadAvatarResult().then { result -> Promise<UIImage> in
                return result.image(ofSize: .preview)
            }
        }
    }
    
    func avatarFromCache() -> Promise<UIImage> {
        if let imageResult = avatarImageResult {
            return imageResult.imageFromCache(size: .preview)
        } else {
            return downloadAvatarResult().then { result in
                return result.imageFromCache(size: .preview)
            }
        }
    }
    
    private func downloadAvatarResult() -> Promise<ImageResult> {
        guard let avatar_id = metadata.avatar_id else { return Promise<ImageResult>(error: UserResultError.noAvatarId(userId: metadata.id)) }
        return ImageRequester().downloadImageResult(withId: avatar_id).then { result -> ImageResult in
            self.avatarImageResult = result
            return result
        }
    }
    
    enum UserResultError: Error {
        case noAvatarId(userId: Int)
        case avatarIsNotSafe(userId: Int)
    }
    
}






