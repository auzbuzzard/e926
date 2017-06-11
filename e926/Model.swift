//
//  Model.swift
//  e926
//
//  Created by Austin Chau on 5/27/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

class ListModel {
    let listType: ListRequester.ListType
    init(ofType type: ListRequester.ListType) {
        listType = type
    }
    
    private(set) var result = ListResult()
    var tags: [String]?
    var stringTags: String? { return tags?.joined(separator: " ") }
    var page = 1
    
    func getResult(reset: Bool = false, tags: [String]?, onComplete: @escaping () -> Void) {
        if reset { result = ListResult(); page = 1 } else { page += 1 }
        self.tags = tags
        _ = ListRequester().downloadList(ofType: listType, tags: tags, last_before_id: nil, page: page)
            .then { listResult -> Void in
                self.result.add(listResult)
                onComplete()
        }
    }
}

class ImageResultModel {
    
}
