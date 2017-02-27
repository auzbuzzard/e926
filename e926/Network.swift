//
//  Network.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    
    case InvalidURL(url: String)
    
    func string() -> String {
        switch self {
        case .InvalidURL(let u):
            return "Network Error: Invalid URL (url: \(u))"
        }
    }
}

class Network {
    
    typealias completionData = (Data) -> Void
    
    static func get(url: String, completion: @escaping completionData) throws {
        do {
            try post(url: url, params: nil, completion: completion)
        } catch let error {
            throw error
        }
    }
    
    static func post(url: String, params: [String]?, completion: @escaping (Data) -> Void) throws {
        guard let u = URL(string: url) else { throw NetworkError.InvalidURL(url: url) }
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: u)
        if params == nil {
            request.httpMethod = "GET"
        } else {
            request.httpMethod = "POST"
            
            let paramString = "data=Hello"
            request.httpBody = paramString.data(using: String.Encoding.utf8)
        }
        //request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (
            data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                print("error")
                return
            }
            
//            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//            print(dataString)
            
            completion(data!)
            
        })
        
        task.resume()
    }
}
