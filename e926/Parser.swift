//
//  Parser.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

protocol Parser {
    associatedtype ParseResult: Result
    static func parse(data: Data) -> Promise<ParseResult>
}

protocol ParserForItem: Parser {
    associatedtype Result: ResultItem
    static func parse(dictionary item: NSDictionary) -> Promise<Result>
}

enum ParserError: Error {
    case JsonDataCorrupted(data: Data)
    case CannotCastJsonIntoNSDictionary(data: Data)
}

class ListParser: Parser {
    static func parse(data: Data) -> Promise<ListResult> {
        return Promise { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<NSDictionary> {
                    
                    var results = [ImageResult]()
                    
                    for item in json {
                        ImageParser.parse(dictionary: item).then { result -> Void in
                            results.append(result)
                            }.catch { error in
                        }
                    }
                    
                    fulfill(ListResult(result: results))
                }
            } catch {
                reject(error)
            }
        }
    }
}

class ImageParser: ParserForItem {
    
    static func parse(data: Data) -> Promise<ImageResult> {
        return Promise { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                    parse(dictionary: json).then { result -> Void in
                        fulfill(result)
                        }.catch { error in
                        reject(error)
                    }
                } else {
                    reject(ParserError.CannotCastJsonIntoNSDictionary(data: data))
                }
            }
        }
    }
    
    static func parse(dictionary item: NSDictionary) -> Promise<ImageResult> {
        let id = item["id"] as? Int ?? 0
        let author = item["author"] as? String ?? ""
        
        let tags = item["tags"] as? String ?? ""
        
        let status = item["status"] as? String ?? ""
        let file_url = item["file_url"] as? String ?? ""
        let file_ext = item["file_ext"] as? String
        let file_size = item["file_size"] as? Int
        
        let width = item["width"] as? Int ?? 1
        let height = item["height"] as? Int ?? 1
        
        let score = item["score"] as? Int ?? 0
        let fav_count = item["fav_count"] as? Int ?? 0
        
        let rating = item["rating"] as? String ?? "e"
        
        let creator_id = item["creator_id"] as? Int ?? 0
        
        
        let sample_width = item["sample_width"] as? Int
        let sample_height = item["sample_height"] as? Int
        let preview_width = item["preview_width"] as? Int
        let preview_height = item["preview_height"] as? Int
        
        let sample_url = item["sample_url"] as? String
        let preview_url = item["preview_url"] as? String ?? ""
        
        var artist = [String]()
        if let item_artist = item["artist"] as? NSArray {
            for i in item_artist  {
                if let a = i as? String {
                    artist.append(a)
                }
            }
        }
        
        let metadata: ImageResult.Metadata = ImageResult.Metadata(id: id, author: author, tags: tags, status: status, file_url: file_url, file_ext: file_ext, file_size: file_size, width: width, height: height, score: score, fav_count: fav_count, rating: rating, creator_id: creator_id, sample_width: sample_width, sample_height: sample_height, preview_width: preview_width, preview_height: preview_height, sample_url: sample_url, preview_url: preview_url, artist: artist)
        return Promise { fulfill, _ in
            fulfill(ImageResult(metadata: metadata))
        }
    }
    
}

class UserParser: Parser {
    
    static func parse(data: Data) -> Promise<UserResult> {
        return Promise { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                    
                    let name = json["name"] as? String ?? ""
                    let id = json["id"] as? Int ?? 0
                    let level = json["level"] as? Int ?? 0
                    
                    let avatar_id = json["avatar_id"] as? Int
                    
                    let metadata = UserResult.Metadata(name: name, id: id, level: level, avatar_id: avatar_id)
                    
                    fulfill(UserResult(metadata: metadata))
                    
                } else {
                    reject(ParserError.CannotCastJsonIntoNSDictionary(data: data))
                }
            } catch {
                reject(error)
            }
        }
    }
}









