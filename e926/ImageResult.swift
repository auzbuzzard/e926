//
//  ImageResult.swift
//  e926
//
//  Created by Austin Chau on 9/17/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

struct ImageResult: ResultItem {
    var id: Int { return metadata.id }
    
    private(set) var metadata: Metadata
    
    struct Metadata: ResultItemMetadata {
        let id: Int
        let author: String
        
        let tags: String
        var tags_array: [String] { return tags.components(separatedBy: " ")}
        let status: String
        var status_enum: Status { return Status(rawValue: status) ?? .pending }
        
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
        return Cache.tag.getTag(withName: singleTag)
            .recover { error -> Promise<TagResult> in
                if case TagCache.CacheError.noTagInStore(_) = error {
                    return TagResultRequester().getTag(withName: singleTag)
                } else {
                    throw error
                }
        }
        
    }
    
    func imageData(for size: Metadata.ImageSize) -> Promise<Data> {
        return firstly {
            if metadata.file_ext_enum == .webm || metadata.file_ext_enum == .swf {
                throw Errors.imageTypeNotSupported(id: id, type: metadata.file_ext_enum)
            } else { return Promise { fulfill, _ in fulfill() } }
        }.then {
            return self.imageDataFromCache(size: size)
        }.recover { error -> Promise<Data> in
            if case ImageCache.CacheError.noImageInStore(_) = error {
                return self.downloadImageData(forSize: size)
            } else { throw error }
        }
    }
    
    func imageDataFromCache(size: Metadata.ImageSize) -> Promise<Data> {
        return Cache.image.getImageData(forId: self.id, size: size)
    }
    
    func downloadImageData(forSize size: Metadata.ImageSize) -> Promise<Data> {
        let url: String = {
            switch size {
            case .file: return metadata.file_url
            case .sample: return metadata.sample_url!
            case .preview: return metadata.preview_url
            }
        }()
        
        return Network.get(url: url).then { data -> Promise<Data> in
            Cache.image.setImageData(data, id: self.id, size: size)
            .catch { print($0) }
            return Promise(value: data)
        }
    }
    
    enum Errors: Error {
        case downloadFailed(id: Int, url: String)
        case imageTypeNotSupported(id: Int, type: Metadata.File_Ext?)
    }
}
