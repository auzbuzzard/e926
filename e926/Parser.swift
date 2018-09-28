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
    associatedtype ParseResult: ModelResult
    static func parse(data: Data) -> Promise<ParseResult>
}

protocol ParserForList {
    associatedtype ParseResult: ModelResult
    static func parse(data: Data) -> Promise<[ParseResult]>
}

protocol ParserForItem {
    associatedtype ParseResult: ResultItem
    static func parse(dictionary item: NSDictionary) -> Promise<ParseResult>
}

extension ParserForItem {
    static func parse(data: Data) -> Promise<ParseResult> {
        return Promise { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                    fulfill(json)
                } else { reject(ParserError.CannotCastJsonIntoNSDictionary(data: data)) }
            } catch { reject(error) }
            }.then(on: .global(qos: .userInitiated)) { json in
                return parse(dictionary: json)
        }
    }
}

enum ParserError: Error {
    case JsonDataCorrupted(data: Data)
    case CannotCastJsonIntoNSDictionary(data: Data)
    case parserGuardFailed(id: String, variable: String)
}

// MARK: - Implementation

struct UserParser: ParserForItem {
    static func parse(dictionary item: NSDictionary) -> Promise<UserResult> {
        guard let id = item["id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "0", variable: "id")) }
        guard let name = item["name"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "name")) }
        guard let level = item["level"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "name")) }
        
        let avatar_id = item["avatar_id"] as? Int
        
        let metadata = UserResult.Metadata(name: name, id: id, level: level, avatar_id: avatar_id)
        return Promise(value: UserResult(metadata: metadata))
    }
}

struct CommentParser: ParserForItem {
    static func parse(data: Data) -> Promise<[CommentResult]> {
        return Promise<Array<NSDictionary>> { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<NSDictionary> {
                    fulfill(json)
                } else { reject(ParserError.CannotCastJsonIntoNSDictionary(data: data)) }
            } catch { reject(error) }
        }.then(on: .global(qos: .userInitiated)) { json in
            return when(resolved: json.map{ return parse(dictionary: $0) })
        }.then(on: .global(qos: .userInitiated)) { results in
            return results.flatMap {
                if case let .fulfilled(value) = $0 { return value } else { return nil }
            }
        }
    }
    
    static func parse(dictionary: NSDictionary) -> Promise<CommentResult> {
        guard let id = dictionary["id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "0", variable: "id")) }
        guard let created_at = dictionary["created_at"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "created_at")) }
        guard let post_id = dictionary["post_id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "post_id")) }
        guard let creator = dictionary["creator"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "creator")) }
        guard let creator_id = dictionary["creator_id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "creator_id")) }
        guard let body = dictionary["body"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "body")) }
        guard let score = dictionary["score"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "score")) }
        
        let metadata = CommentResult.Metadata(id: id, created_at: created_at, post_id: post_id, creator: creator, creator_id: creator_id, body: body, score: score)
        
        return Promise(value: CommentResult(metadata: metadata))
    }
}

struct TagParser: ParserForItem {
    static func parse(data: Data) -> Promise<TagResult> {
        return Promise<NSDictionary> { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<NSDictionary> {
                    fulfill(json[0])
                } else { reject(ParserError.CannotCastJsonIntoNSDictionary(data: data)) }
            } catch { reject(error) }
        }.then(on: .global(qos: .userInitiated)) { return parse(dictionary: $0) }
    }
    
    static func parse(dictionary item: NSDictionary) -> Promise<TagResult> {
        guard let id = item["id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "0", variable: "id")) }
        guard let name = item["name"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "name")) }
        guard let count = item["count"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "count")) }
        guard let type = item["type"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "type")) }
    
        let metadata = TagResult.Metadata(id: id, name: name, count: count, type: type)
        
        return Promise(value: TagResult(metadata: metadata))
    }
}

class PoolResultParser: ParserForItem {
    static func parse(dictionary item: NSDictionary) -> Promise<PoolResult> {
        guard let id = item["id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "0", variable: "id")) }
        
        guard let created_at: (json_class: String, s: Int, n: Int) = {
            if let dict = item["created_at"] as? NSDictionary,
            let json_class = dict["json_class"] as? String,
            let s = dict["s"] as? Int,
            let n = dict["n"] as? Int {
                return (json_class, s, n)
            } else { return nil }
        }() else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "created_at")) }
        guard let description = item["description"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "description")) }
        
        guard let is_active = item["is_active"] as? Bool else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "is_active")) }
        guard let is_locked = item["is_locked"] as? Bool else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "is_locked")) }
        guard let name = item["name"] as? String else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "name")) }
        guard let post_count = item["post_count"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "post_count")) }
        
        guard let updated_at: (json_class: String, s: Int, n: Int) = {
            if let dict = item["updated_at"] as? NSDictionary,
            let json_class = dict["json_class"] as? String,
            let s = dict["s"] as? Int,
            let n = dict["n"] as? Int {
                return (json_class, s, n)
            } else { return nil }
        }() else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "updated_at")) }
        guard let user_id = item["user_id"] as? Int else { return Promise(error: ParserError.parserGuardFailed(id: "\(id)", variable: "user_id")) }
        
        return Promise<Array<NSDictionary>> { fulfill, reject in
            guard let array = item["posts"] as? Array<NSDictionary> else { reject(ParserError.parserGuardFailed(id: "\(id)", variable: "posts")); return }
            fulfill(array)
        }.then(on: .global(qos: .userInitiated)) { array in
            return when(resolved: array.map{ ImageParser.parse(dictionary: $0) })
        }.then(on: .global(qos: .userInitiated)) { results -> [ImageResult] in
            return results.flatMap {
                if case let .fulfilled(value) = $0 { return value } else { return nil }
            }
        }.then { posts -> Promise<PoolResult> in
            let metadata = PoolResult.Metadata(created_at: created_at, description: description, id: id, is_active: is_active, is_locked: is_locked, name: name, post_count: post_count, updated_at: updated_at, user_id: user_id, posts: posts)
            return Promise(value: PoolResult(metadata: metadata))
        }

    }
}




