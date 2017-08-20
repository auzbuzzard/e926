//
//  Server.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit
import Fuzi

class Requester {
    static var base_url: String {
        return UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue) ? "https://e621.net" : "https://e926.net"
    }
}


class ListRequester: Requester {
    enum ListType { case post, user }
    
    static var list_post_url: String { return base_url + "/post/index.json" }
    static var list_user_url: String { return base_url + "/user/index.json" }
    
    func downloadList(ofType listType: ListType, tags: [String]?, last_before_id: Int? = nil, page: Int?) -> Promise<ListResult> {
        var params = [String]()
        
        if let last_before_id = last_before_id {
            params.append("before_id=\(last_before_id)")
        } else if let page = page {
            params.append("page=\(page)")
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
        
        let network = Network.get(url: url)
        let tags = Censor.bannedTagsPromise!
        
        return when(resolved: tags).then { _ -> Promise<Data> in
            return network
        }.then(on: .global(qos: .userInitiated)) { data -> Promise<ListResult> in
            return ListParser.parse(data: data)
        }
    }
    
}

class ImageRequester: Requester {
    static var image_url: String { return base_url + "/post/show" }
    
    func getUrl(withId id: Int, withoutJson: Bool = false) -> String {
        return ImageRequester.image_url + "/\(id)\(withoutJson ? "" : ".json")"
    }
    func downloadImageResult(withId id: Int) -> Promise<ImageResult> {
        let url = getUrl(withId: id)
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
    static let pool_url = base_url + "/pool"
    func getPool(forImage id: Int) -> Promise<PoolResult> {
        let url = ImageRequester().getUrl(withId: id, withoutJson: true)
        return Network.getWithAlamo(url: url).responseString().then { response in
            //print(response)
            
            let doc = try? HTMLDocument(cChars: (response.cString(using: .utf8))!)
            let element = doc?.xpath("//*[@id=\"post-view\"]/div[1]/div[2]").first
            //print(doc?.body)
            if let attr = element?.attributes, attr["class"] == "status-notice", let link = element?.children.first?.children(tag: "p").first?.children(tag: "a").first, let url = link.attributes["href"] {
                return self.getPool(withLink: url)
            } else {
                return Promise<PoolResult>(error: PoolRequestError.cannotParseHTML(id: id))
            }
        }
    }
    
    func getPool(withId id: Int, page: Int) -> Promise<PoolResult> {
        let url = PoolRequester.pool_url + "/show/\(id).json?page=\(page)"
        print(url)
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<PoolResult> in
            return PoolResultParser.parse(data: data)
        }
    }
    
    private func getPool(withLink linkUrl: String) -> Promise<PoolResult> {
        let url = Requester.base_url + linkUrl + ".json"
        //print(url)
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<PoolResult> in
            return PoolResultParser.parse(data: data)
        }
    }
    
    enum PoolRequestError: Error {
        case cannotParseHTML(id: Int)
    }
}



