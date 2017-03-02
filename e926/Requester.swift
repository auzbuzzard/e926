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
    static var base_url: String {
        if UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue) {
            return "https://e621.net"
        } else {
            return "https://e926.net"
        }
    }
}


class ListRequester: Requester {
    enum ListType {
        case post, user
    }
    
    static var list_post_url: String { get { return base_url + "/post/index.json" } }
    static var list_user_url: String { get { return base_url + "/user/index.json" } }
    
    func downloadList(OfType listType: ListType, tags: String?, last_before_id: Int?) -> Promise<ListResult> {
        var url = ""
        switch listType {
        case.post: url.append(ListRequester.list_post_url)
        case.user: url.append(ListRequester.list_user_url)
        }
        
        var params = [String]()
        
        if let last_before_id = last_before_id {
            params.append("before_id=\(last_before_id)")
        }
        if let tags = tags {
            params.append("tags=\(tags)")
        }
        
        url.append("?\(params.joined(separator: "&"))")
        
        print(url)
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<ListResult> in
            return ListParser.parse(data: data)
        }
    }
    
}

class ImageRequester: Requester {
    static var image_url: String { get { return base_url + "/post/show" } }
    
    func downloadImageResult(withId id: Int) -> Promise<ImageResult> {
        let url = ImageRequester.image_url + "/\(id).json"
        return Network.get(url: url).then(on: .global(qos: .userInitiated)) { data -> Promise<ImageResult> in
            return ImageParser.parse(data: data)
        }
    }
}

class UserRequester: Requester {
    static let user_url = base_url + "/user/index"
    static let user_show_url = base_url + "/user/show"
    
    func getUser(WithId id: Int) -> Promise<UserResult> {
        return userFromCache(id: id)
            .recover { error -> Promise<UserResult> in
                if case Cache.CacheError.noUserInStore(_) = error {
                    return self.downloadUser(withId: id)
                } else {
                    throw error
                }
        }
    }
    
    func userFromCache(id: Int) -> Promise<UserResult> {
        return Cache.shared.getUser(withId: id)
    }
    
    func downloadUser(withId id: Int) -> Promise<UserResult> {
        let url = UserRequester.user_show_url + "/\(id).json"
        return Network.get(url: url)
            .then(on: .global(qos: .userInitiated)) { data -> Promise<UserResult> in
                return UserParser.parse(data: data)
            }.then(on: .global(qos: .userInitiated)) { result -> UserResult in
                _ = Cache.shared.setUser(result)
                return result
        }
    }
}

class PoolRequester: Requester {
    
}



