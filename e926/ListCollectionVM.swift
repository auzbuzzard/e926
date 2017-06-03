//
//  ListCollectionVM.swift
//  e926
//
//  Created by Austin Chau on 5/27/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

protocol ListCollectionVMProtocol {
    var results: [ImageResult] { get }
    var tags: [String]? { get }
    func getResults(asNew: Bool, withTags tags: [String]?, onComplete: @escaping () -> Void)
}

class ListCollectionVM: ListCollectionVMProtocol {
    private var model = ListModel(ofType: .post)
    var results: [ImageResult] { return model.result.results }
    var tags: [String]? { get { return model.tags } set { model.tags = newValue } }
    
    func getResults(asNew: Bool = false, withTags tags: [String]? = nil, onComplete: @escaping () -> Void) {
        model.getResult(reset: asNew, tags: tags, onComplete: onComplete)
    }
    
    func setTags(_ unformattedTags: String) {
        tags = unformattedTags.components(separatedBy: ",").map { $0.replacingOccurrences(of: " ", with: "") }
    }
}



















