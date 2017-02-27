//
//  Server.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation

class Requester {
    static var base_url: String {
        get {
            if UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue) {
                return "https://e621.net"
            } else {
                return "https://e926.net"
            }
        }
        
    }
}

class ListRequester: Requester {
    typealias completion = (ListResult) -> Void
    
    enum ListType {
        case post, user
    }
    
    static var list_post_url: String { get { return base_url + "/post/index.json" } }
    static var list_user_url: String { get { return base_url + "/user/index.json" } }
    
    func get(listOfType listType: ListType, tags: String?, result: ListResult?, completion: @escaping completion) {
        var url = ""
        switch listType {
        case.post: url.append(ListRequester.list_post_url)
        case.user: url.append(ListRequester.list_user_url)
        }
        
        var params = [String]()
        
        if let last_before_id = result?.last_before_id {
            params.append("before_id=\(last_before_id)")
        }
        if let tags = tags {
            params.append("tags=\(tags)")
        }
        
        url.append("?\(params.joined(separator: "&"))")
        
        print(url)
        do {
            try Network.get(url: url) {
                data in
                DispatchQueue.global().async {
                    do {
                        let r = result ?? ListResult()
                        try ListParser.parse(data: data, toResult: r)
                        completion(r)
                    } catch {
                        print(error)
                    }
                }
            }
        } catch {
            print("ListRequester Error \(error)")
        }
    }
    
}

class ImageRequester: Requester {
    typealias completion = (ImageResult) -> Void
    
    static var image_url: String { get { return base_url + "/post/show" } }
    
    func get(imageResultWithId id: Int, completion: @escaping completion) {
        let url = ImageRequester.image_url + "/\(id).json"
        do {
            try Network.get(url: url) { data in
                DispatchQueue.global().async {
                    do {
                        let result = try ImageParser.parse(data: data)
                        completion(result)
                    } catch {
                        print("ImageRequester get error")
                    }
                }
            }
        } catch {
            print("ImageRequester Error")
        }
    }
    
}

class UserRequester: Requester {
    typealias completion = (UserResult) -> Void
    
    static let user_url = base_url + "/user/index"
    static let user_show_url = base_url + "/user/show"
    
    func get(userWithId id: Int, fallback: @escaping (Bool) -> Void) -> UserResult? {
        if let user = try? Cache.shared.getUser(withId: id) {
            return user
        } else {
            let url = UserRequester.user_show_url + "/\(id).json"
            do {
                try Network.get(url: url) { data in
                    DispatchQueue.global().async {
                        do {
                            let result = try UserParser.parse(data: data)
                            do {
                                try Cache.shared.setUser(result)
                                fallback(true)
                            } catch {
                                fallback(false)
                            }
                        } catch {
                            print("UserRequester get error: \(data) of url: \(url)")
                            fallback(false)
                        }
                    }
                }
            } catch {
                print("UserRequester Error")
                fallback(false)
            }
            return nil
        }
        
    }
    
}

class PoolRequester: Requester {
    
}



