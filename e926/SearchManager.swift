//
//  SearchManager.swift
//  e926
//
//  Created by Austin Chau on 10/10/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

class SearchManager: ListCollectionVCRequestDelegate {
    
    //static let shared = Lis
    
    var listVC: ListCollectionVC!
    var searchString: String?
    var searchStringCorrected: String? {
        get {
            return searchString?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        }
    }
    
    internal func vcShouldLoadImmediately() -> Bool {
        return true
    }
    
    func getResult(last_before_id: Int?) -> Promise<ListResult> {
        return ListRequester().downloadList(OfType: .post, tags: searchStringCorrected, last_before_id: last_before_id)
    }
}
