//
//  Server.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

class Requester {
    static var base_url: String = UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue) ? "https://e621.net" : "https://e926.net"
}


class ListRequester: Requester {
    enum ListType { case post, user }
    
    static var list_post_url: String { return base_url + "/post/index.json" }
    static var list_user_url: String { return base_url + "/user/index.json" }
    
    func downloadList(ofType listType: ListType, tags: [String]?, last_before_id: Int?) -> Promise<ListResult> {
        var params = [String]()
        
        if let last_before_id = last_before_id {
            params.append("before_id=\(last_before_id)")
        }
        if let tags = tags {
            params.append("tags=\(tags.joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)")
        }
        #if DEBUG
            //params.append("limit=10")
        #endif
        
        let url: String = {
            switch listType {
            case.post: return ListRequester.list_post_url + "?\(params.joined(separator: "&"))"
            case.user: return ListRequester.list_user_url + "?\(params.joined(separator: "&"))"
            }
        }()
        #if DEBUG
            print(url)
        #endif
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<ListResult> in
            return ListParser.parse(data: data)
        }
    }
    
}

class ImageRequester: Requester {
    static var image_url: String { return base_url + "/post/show" }
    
    func downloadImageResult(withId id: Int) -> Promise<ImageResult> {
        let url = ImageRequester.image_url + "/\(id).json"
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<ImageResult> in
            return ImageParser.parse(data: data)
            }
    }
}

class UserRequester: Requester, UsingUserCache {
    static let user_url = base_url + "/user/index"
    static let user_show_url = base_url + "/user/show"
    
    func getUser(WithId id: Int) -> Promise<UserResult> {
        return userFromCache(id: id)
            .recover { error -> Promise<UserResult> in
                if case UserCache.CacheError.noUserInStore(_) = error {
                    return self.downloadUser(withId: id)
                } else {
                    throw error
                }
        }
    }
    
    func userFromCache(id: Int) -> Promise<UserResult> {
        return userCache.getUser(withId: id)
    }
    
    func downloadUser(withId id: Int) -> Promise<UserResult> {
        let url = UserRequester.user_show_url + "/\(id).json"
        return Network.get(url: url)
            .then(on: .global(qos: .userInitiated)) { data -> Promise<UserResult> in
                return UserParser.parse(data: data)
            }.then(on: .global(qos: .userInitiated)) { result -> UserResult in
                _ = self.userCache.setUser(result)
                return result
        }
    }
}

class CommentRequester: Requester {
    static let list_url = base_url + "/comment"
    enum ReturnStatus: String { case hidden = "hidden", active = "active", any = "any" }
    
    func getComments(for post_id: Int, page: Int?, status: ReturnStatus?) -> Promise<ListCommentResult> {
        
        var params = [String]()
        params.append("post_id=\(post_id)")
        if let page = page {
            params.append("page=\(page)")
        }
        if let status = status {
            params.append("tags=\(status.rawValue)")
        }
        let url = CommentRequester.list_url + "/index.json?" + params.joined(separator: "&")
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<ListCommentResult> in
            return ListCommentParser.parse(data: data)
        }
    }
}

class TagResultRequester: Requester, UsingTagCache {
    static let tag_url = base_url + "/tag"
    func getTag(withName name: String) -> Promise<TagResult> {
        let url = TagResultRequester.tag_url + "/index.json?" + "name=\(name)"
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<TagResult> in
            return TagParser.parse(data: data)
            }.then(on: .global(qos: .userInitiated)) { tagResult -> TagResult in
            _ = self.tagCache.setTag(tagResult)
            return tagResult
        }
    }
}

class PoolRequester: Requester {
    
}



