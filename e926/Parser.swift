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

protocol ParserForItem {
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
                            }.catch { error -> Void in
                                if case ImageParser.ImageParserError.imageIsCensored(_, _) = error {
                                    
                                } else if case ImageParser.ImageParserError.imageTypeIsNotSupported(_, _) = error {
                                    
                                }
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

class ImageParser: ParserForItem, UsingTagCache {
    
    static func imageShouldBeCensored(status: String) -> Bool {
        guard let status_enum = ImageResult.Metadata.Status(rawValue: status) else { return true }
        switch Identity.censorMode {
        case .strong: return status_enum == .active ? false : true
        case .safe, .none: return false
        }
    }
    
    static func imageTypeIsSupported(file_ext: String) -> Bool {
        guard let status_enum = ImageResult.Metadata.File_Ext(rawValue: file_ext) else { return false }
        switch status_enum {
        case .jpg, .png, .gif: return true
        case .swf, .webm: return false
        }
    }
    
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
        
        if file_ext == nil || !imageTypeIsSupported(file_ext: file_ext!) {
            return Promise { _, reject in
                reject(ImageParserError.imageTypeIsNotSupported(id: id, status: {
                    if file_ext != nil { return ImageResult.Metadata.File_Ext(rawValue: file_ext!) ?? .jpg }
                    else { return .jpg }
                }()))
            }
        }
        
        if imageShouldBeCensored(status: status) {
            return Promise { _, reject in
                reject(ImageParserError.imageIsCensored(id: id, status: ImageResult.Metadata.Status(rawValue: status) ?? .pending))
            }
        }
        
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
    
    
    enum ImageParserError: Error {
        case imageIsCensored(id: Int, status: ImageResult.Metadata.Status)
        case imageTypeIsNotSupported(id: Int, status: ImageResult.Metadata.File_Ext)
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

class ListCommentParser: Parser {
    static func parse(data: Data) -> Promise<ListCommentResult> {
        return Promise { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<NSDictionary> {
                    
                    var results = [CommentResult]()
                    
                    for item in json {
                        CommentParser.parse(dictionary: item).then { result -> Void in
                            results.append(result)
                            }.catch { error in
                        }
                    }
                    fulfill(ListCommentResult(result: results))
                }
            } catch {
                reject(error)
            }
        }
    }
}

class CommentParser: ParserForItem {    
    static func parse(dictionary: NSDictionary) -> Promise<CommentResult> {
        return Promise { fulfill, _ in
            let id = dictionary["id"] as? Int ?? 0
            let created_at = dictionary["created_at"] as? String ?? ""
            let post_id = dictionary["post_id"] as? Int ?? 0
            let creator = dictionary["creator"] as? String ?? ""
            let creator_id = dictionary["creator_id"] as? Int ?? 0
            let body = dictionary["body"] as? String ?? ""
            let score = dictionary["score"] as? Int ?? 0
            
            let metadata = CommentResult.Metadata(id: id, created_at: created_at, post_id: post_id, creator: creator, creator_id: creator_id, body: body, score: score)
            
            fulfill(CommentResult(metadata: metadata))
        }
    }
}

class TagParser: Parser {
    static func parse(data: Data) -> Promise<TagResult> {
        return Promise { fulfill, reject in
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<NSDictionary> {
                    let json = jsonArray[0]
                    
                    let id = json["id"] as? Int ?? 0
                    let name = json["name"] as? String ?? ""
                    let count = json["count"] as? Int ?? 0
                    let type = json["type"] as? Int ?? 0
                    
                    let metadata = TagResult.Metadata(id: id, name: name, count: count, type: type)
                    
                    fulfill(TagResult(metadata: metadata))
                }
            } catch {
                reject(error)
            }
            
            
        }
    }
}

class PoolResultParser: Parser {
    static func parse(data: Data) -> Promise<PoolResult> {
        return Promise { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                    
                    let created_at: (json_class: String, s: Int, n: Int) = {
                        let dict = json["created_at"] as? NSDictionary
                        let json_class = dict?["json_class"] as? String ?? ""
                        let s = dict?["s"] as? Int ?? 0
                        let n = dict?["n"] as? Int ?? 0
                        return (json_class, s, n)
                    }()
                    let description = json["description"] as? String ?? ""
                    let id = json["id"] as? Int ?? 0
                    let is_active = json["is_active"] as? Bool ?? false
                    let is_locked = json["is_locked"] as? Bool ?? true
                    let name = json["name"] as? String ?? ""
                    let post_count = json["post_count"] as? Int ?? 0
                    let updated_at: (json_class: String, s: Int, n: Int) = {
                        let dict = json["updated_at"] as? NSDictionary
                        let json_class = dict?["json_class"] as? String ?? ""
                        let s = dict?["s"] as? Int ?? 0
                        let n = dict?["n"] as? Int ?? 0
                        return (json_class, s, n)
                    }()
                    let user_id = json["user_id"] as? Int ?? 0
                    
                    let posts: [ImageResult] = {
                        var result = [ImageResult]()
                        if let array = json["posts"] as? Array<NSDictionary> {
                            for item in array {
                                _ = ImageParser.parse(dictionary: item).then { img in
                                    result.append(img)
                                }
                            }
                        }
                        return result
                    }()
                    
                    let metadata = PoolResult.Metadata(created_at: created_at, description: description, id: id, is_active: is_active, is_locked: is_locked, name: name, post_count: post_count, updated_at: updated_at, user_id: user_id, posts: posts)
                    
                    fulfill(PoolResult(metadata: metadata))
                }
            } catch {
                reject(error)
            }
            
            
        }
    }
}




