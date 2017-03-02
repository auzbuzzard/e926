//
//  Network.swift
//  E621
//
//  Created by Austin Chau on 10/6/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

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
    
    static func get(url: String) -> Promise<Data> {
        return post(url: url, params: nil)
    }
    
    static func post(url: String, params: [String]?) -> Promise<Data> {
        return Promise { fulfill, reject in
            guard let u = URL(string: url) else { reject(NetworkError.InvalidURL(url: url)); return }
            let session = URLSession.shared

            let request = NSMutableURLRequest(url: u)
            if params == nil {
                request.httpMethod = "GET"
            } else {
                request.httpMethod = "POST"
                
                let paramString = "data=Hello"
                request.httpBody = paramString.data(using: String.Encoding.utf8)
            }
            
            let dataPromise: URLDataPromise = session.dataTask(with: request as URLRequest)
            dataPromise.asDataAndResponse().then { (data, respone) -> Void in
                fulfill(data)
                }.catch(execute: reject)
        }
    }
}
