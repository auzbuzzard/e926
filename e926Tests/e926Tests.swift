//
//  e926Tests.swift
//  e926Tests
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import XCTest
import Alamofire
@testable import e926

class e926Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let str = "https://e621.net/user/authenticate"
        let param = [
            "user[name]" : "anonymoushawk",
            "user[password]" : "tamedyiffyfoxxx"
        ]
        
        let request = Network.postWithAlamo(url: str, params: param, encoding: JSONEncoding.default)
        request.responseJSON { response in
            //print(response)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
