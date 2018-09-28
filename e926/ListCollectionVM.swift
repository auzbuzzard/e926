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
    
    // MARK: - Internal Data
    
    private var result: ListResult
    
    init(result: ListResult) {
        self.result = result
    }
    
    // MARK: - Interface
    
    var results: [ImageResult] { return result.results }
    var tags: [String]? { return result.tags }
    var poolId: Int?
    
    func getResults(asNew reset: Bool = true, withTags tags: [String]? = nil) -> Promise<Void> {
        if reset { result = ListResult() }
        result.tags = tags
        return ListRequester().downloadList(ofType: .post, tags: tags, page: result.currentPage + 1)
        .then { listResult in
            self.result.add(listResult)
        }
    }
    
    func getResults(asNew reset: Bool = true, withStringTags tag: String? = nil) -> Promise<Void> {
        return getResults(asNew: reset, withTags: tags(from: tag))
    }
    func getPool(asNew: Bool, poolId: Int) -> Promise<Void> {
        return Promise(error: Errors.wrongDataSource)
    }
    
    func tags(from stringTag: String?) -> [String]? {
        return stringTag?.components(separatedBy: " ")
    }
    
    enum Errors: Error {
        case wrongDataSource
    }
}

/// View Model for ListCollectionVCMainCell
struct ListCollectionVCMainCellVM: ListCollectionVCMainCellDataSource {
    let imageResult: ImageResult
    
    init(imageResult: ImageResult) {
        self.imageResult = imageResult
    }
    
    var artistsName: String { return imageResult.metadata.artist?.joined(separator: ", ") ?? "(no artist)" }
    var authorName: String { return imageResult.metadata.author }
    var favCount: Int { return imageResult.metadata.fav_count }
    var score: Int { return imageResult.metadata.score }
    var rating: ImageResult.Metadata.Rating { return imageResult.metadata.rating_enum }
    
    var imageType: ImageResult.Metadata.File_Ext { return imageResult.metadata.file_ext_enum ?? .jpg }
    var mainImageData: Promise<Data> {
        return imageResult.imageData(for: .sample)
    }
    var profileImageData: Promise<Data> {
        return Promise<Data>(error: UserResult.Errors.noAvatarId(userId: 0))
    }
}

class ListCollectionPoolVM: ListCollectionDataSource {
    
    var result: PoolResult!
    
    var results: [ImageResult] { return result?.metadata.posts ?? [ImageResult]() }
    var tags: [String]?
    var poolId: Int? { return result?.id }
    var currentPage = 1
    
    func getResults(asNew: Bool, withTags tags: [String]?) -> Promise<Void> {
        return Promise(error: Errors.wrongDataSource)
    }
    
    func getPool(asNew: Bool, forImage id: Int) -> Promise<Void> {
        return PoolRequester().getPool(forImage: id).then { result in
            self.result = result
        }
    }
    func getPool(asNew reset: Bool, poolId: Int) -> Promise<Void> {
        if reset { self.result.results = [ImageResult](); self.currentPage = 1 }
        return PoolRequester().getPool(withId: poolId, page: currentPage + 1).then { result -> Void in
            self.result?.add(result)
            self.currentPage += 1
        }
    }
    
    enum Errors: Error {
        case wrongDataSource
    }
    
}

class ImageDetailCommentVM {
    var post_id: Int
    init(post_id: Int) { self.post_id = post_id }
    
    lazy var results = [CommentResult]()
    private var lastPage: Int = 0
    func getResults(page: Int?) -> Promise<Void> {
        return CommentRequester().getComments(for: post_id, page: page ?? lastPage + 1, status: nil).then { result -> Void in
            self.results.append(contentsOf: result)
            self.lastPage = page ?? (self.lastPage + 1)
        }
    }
}

















