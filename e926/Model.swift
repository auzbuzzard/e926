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
    var formattedTags: String? { return tags != nil ?formatTags(tags!) : nil }
    
    
    func getResult(reset: Bool = false, tags: [String]?, onComplete: @escaping () -> Void) {
        if reset { result = ListResult() }
        self.tags = tags
        _ = ListRequester().downloadList(ofType: listType, formattedTags: formattedTags, last_before_id: result.last_before_id)
            .then { listResult -> Void in
            self.result.add(listResult)
            onComplete()
        }
    }
    
    private func formatTags(_ tags: [String]) -> String {
        return tags.map { $0.components(separatedBy: " ").joined(separator: "_") }.joined(separator: ", ")
    }
}

class ImageResultModel {
    
}
