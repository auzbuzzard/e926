//
//  ImageParser.swift
//  e926
//
//  Created by Austin Chau on 9/17/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

struct ImageParser: ParserForItem {
    
    static func imageShouldBeCensored(status: String, tags: String) -> Bool {
        let tagsArr = tags.components(separatedBy: " ")
        if Censor.censorMode == .strong && tagsArr.contains(where: {Censor.bannedTags.contains($0)}) {
            return true
        }
        
        guard let status_enum = ImageResult.Metadata.Status(rawValue: status) else { return true }
        switch Censor.censorMode {
        case .strong: return status_enum == .active ? false : true
        case .safe, .none: return false
        }
    }
    
    static func parse(dictionary item: NSDictionary) -> Promise<ImageResult> {
        guard let id = item["id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "0", variable: "id")) }
        guard let author = item["author"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "author")) }
        
        guard let tags = item["tags"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "tags")) }
        
        guard let status = item["status"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "status")) }
        guard let file_url = item["file_url"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "file_url")) }
        let file_ext = item["file_ext"] as? String
        let file_size = item["file_size"] as? Int

        if imageShouldBeCensored(status: status, tags: tags) {
            return Promise(error: Errors.imageIsCensored(id: id, status: ImageResult.Metadata.Status(rawValue: status) ?? .pending))
        }
        
        guard let width = item["width"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "width")) }
        guard let height = item["height"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "height")) }
        
        guard let score = item["score"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "score")) }
        guard let fav_count = item["fav_count"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "fav_count")) }
        
        guard let rating = item["rating"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "rating")) }
        
        guard let creator_id = item["creator_id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "creator_id")) }
        
        
        let sample_width = item["sample_width"] as? Int
        let sample_height = item["sample_height"] as? Int
        let preview_width = item["preview_width"] as? Int
        let preview_height = item["preview_height"] as? Int
        
        let sample_url = item["sample_url"] as? String
        guard let preview_url = item["preview_url"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "preview_url")) }
        
        guard let artist: [String] = {
            guard let item_artist = item["artist"] as? NSArray else { return nil }
            return item_artist.filter{ $0 is String }.map { $0 as! String }
        }() else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "artist")) }
        
        let metadata: ImageResult.Metadata = ImageResult.Metadata(id: id, author: author, tags: tags, status: status, file_url: file_url, file_ext: file_ext, file_size: file_size, width: width, height: height, score: score, fav_count: fav_count, rating: rating, creator_id: creator_id, sample_width: sample_width, sample_height: sample_height, preview_width: preview_width, preview_height: preview_height, sample_url: sample_url, preview_url: preview_url, artist: artist)
        
        
        return Promise(value: ImageResult(metadata: metadata))
    }
    
    
    enum Errors: Error {
        case imageIsCensored(id: Int, status: ImageResult.Metadata.Status)
        case imageTypeIsNotSupported(id: Int, status: ImageResult.Metadata.File_Ext)
    }
}
