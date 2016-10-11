//
//  Result.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit

class Result {
    
}

class ListResult: Result {
    
    lazy var results = [ImageResult]()
    
    var last_before_id: Int?
    
    func add(results newResults: [ImageResult]) {
        results.append(contentsOf: newResults)
        last_before_id = results.last?.id
    }
    
}

class ImageResult: Result {
    
    var id: Int { get { return metadata.id } }
    
    var metadata: Metadata {
        didSet {
            _ = getImage(ofSize: .sample, callback: { _ in })
        }
    }
    
    struct Metadata {
        let id: Int
        let author: String
        
        let tags: String
        
        let status: String
        
        let file_url: String
        var file_ext: String?
        var file_size: Int?
        
        let width: Int
        let height: Int
        
        let score: Int
        let fav_count: Int
        
        let rating: String
        
        let creator_id: Int
        
        let sample_width: Int?
        let sample_height: Int?
        
        let preview_width: Int?
        let preview_height: Int?
        
        var sample_url: String?
        let preview_url: String
        
        let artist: [String]?
        
        enum Status: String {
            case active, flagged, pending, deleted
        }
        enum File_Ext: String {
            case jpg, png, gif, swf, webm
        }
        enum ImageSize: String {
            case file, sample, preview
        }
        enum Rating: String {
            case s, q, e
        }
        
        func width(ofSize size: ImageSize) -> Int? {
            switch size {
            case .file: return width
            case .sample: return sample_width
            case .preview: return preview_width
            }
        }
        
        func height(ofSize size: ImageSize) -> Int? {
            switch size {
            case .file: return height
            case .sample: return sample_height
            case .preview: return preview_height
            }
        }
    }
    
    func hasImageInCache(ofSize size: Metadata.ImageSize) -> Bool {
        if let _ = try? Cache.shared.getImage(size: size, id: self.id) {
            return true
        } else {
            return false
        }
    }
    
    func getImage(ofSize size: Metadata.ImageSize, callback: ((_ image: UIImage?, ImageResultError?) -> Void)?) -> UIImage? {
        if let image = try? Cache.shared.getImage(size: size, id: self.id) {
            callback?(image, nil)
            return image
        } else {
            if let callback = callback {
                var url = ""
                switch size {
                case .file: url = metadata.file_url
                case .sample: url = metadata.sample_url!
                case .preview: url = metadata.preview_url
                }
                do {
                    try Network.get(url: url, completion: { data in
                        if let image = UIImage(data: data) {
                            do {
                                try Cache.shared.setImage(size: size, image: image, forID: self.id)
                                callback(image, nil)
                            } catch {
                                print("store error")
                            }
                        } else {
                            callback(nil, ImageResultError.ImageDownloadError(id: self.id, url: url))
                        }
                    })
                } catch {
                    print("getImage error")
                }
            }
            return nil
        }
    }
    
    func setImage(ofSize size: Metadata.ImageSize, image: UIImage) {
        
    }
    
    init(metadata: Metadata) {
        self.metadata = metadata
    }
    
    enum ImageResultError: Error {
        case ImageDownloadError(id: Int, url: String)
        case ImageNotInCache(id: Int)
    }
}

class UserResult: Result {
    
    var id: Int { get { return metadata.id } }
    
    var metadata: Metadata
    
    struct Metadata {
        let name: String
        let id: Int
        let level: Int
        let avatar_id: Int?
    }
    
    init(metadata: Metadata) {
        self.metadata = metadata
    }
    
}






