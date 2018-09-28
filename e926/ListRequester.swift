//
//  ListRequester.swift
//  e926
//
//  Created by Austin Chau on 9/17/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

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
