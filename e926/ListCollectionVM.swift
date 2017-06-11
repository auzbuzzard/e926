//
//  ListCollectionVM.swift
//  e926
//
//  Created by Austin Chau on 5/27/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

class ListCollectionVM: ListCollectionDataSource {
    private var model = ListModel(ofType: .post)
    
    var results: [ImageResult] { return model.result.results }
    var tags: [String]? { get { return model.tags } set { model.tags = newValue } }
    var poolId: Int?
    
    func getResults(asNew: Bool = true, withTags tags: [String]? = nil, onComplete: @escaping () -> Void) {
        model.getResult(reset: asNew, tags: tags, onComplete: onComplete)
    }
    
    func getResults(asNew: Bool = true, withStringTags tag: String? = nil, onComplete: @escaping () -> Void) {
        getResults(asNew: asNew, withTags: tags(from: tag), onComplete: onComplete)
    }
    func getPool(asNew: Bool, poolId: Int, onComplete: @escaping () -> Void) {
        onComplete()
    }
    
    func tags(from stringTag: String?) -> [String]? {
        return stringTag?.components(separatedBy: " ")
    }
}

class ListCollectionPoolVM: ListCollectionDataSource {
    var result: PoolResult!
    
    var results: [ImageResult] { return result?.metadata.posts ?? [ImageResult]() }
    var tags: [String]?
    var poolId: Int? { return result?.id }
    var currentPage = 1
    
    func getResults(asNew: Bool, withTags tags: [String]?, onComplete: @escaping () -> Void) {
        onComplete()
    }
    
    func getPool(asNew: Bool, forImage id: Int, onComplete: @escaping () -> Void) {
        print("VM: Getting Pool")
        _ = PoolRequester().getPool(forImage: id).then { result -> Void in
            self.result = result
            onComplete()
        }
    }
    func getPool(asNew: Bool, poolId: Int, onComplete: @escaping () -> Void) {
        if asNew { self.result.results = [ImageResult](); self.currentPage = 1 }
        _ = PoolRequester().getPool(withId: poolId, page: currentPage + 1).then { result -> Void in
            self.result?.add(result)
            onComplete()
        }
    }
    
    
}

class ImageDetailCommentVM {
    var post_id: Int
    init(post_id: Int) { self.post_id = post_id }
    private var model = ListCommentResult()
    var results: [CommentResult] { return model.results }
    private var lastPage: Int = 0
    func getResults(page: Int?, onComplete: @escaping () -> Void) {
        _ = CommentRequester().getComments(for: post_id, page: page ?? lastPage + 1, status: nil).then {
            result -> Void in
            self.model.add(result)
            self.lastPage = page ?? (self.lastPage + 1)
            onComplete()
        }
    }
}

















