//
//  ListParser.swift
//  e926
//
//  Created by Austin Chau on 9/17/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

struct ListParser {
    static func parse(data: Data) -> Promise<ListResult> {
        return Promise<Array<NSDictionary>> { fulfill, reject in
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Array<NSDictionary> {
                    fulfill(json)
                } else { reject(ParserError.CannotCastJsonIntoNSDictionary(data: data)) }
            } catch { reject(error) }
        }.then(on: .global(qos: .userInitiated)) { json in
            return when(resolved: json.map { ImageParser.parse(dictionary: $0) })
        }.then(on: .global(qos: .userInitiated)) { results -> [ImageResult] in
            return results.flatMap {
                if case let .fulfilled(value) = $0 { return value }
                else if case let .rejected(error) = $0 { print(error); return nil }
                else { return nil }
            }
        }.then {
            return Promise(value: ListResult(result: $0))
        }
    }
}
