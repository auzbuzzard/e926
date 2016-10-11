//
//  Identity.swift
//  E621
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation

class Identity {
    
    static let main = Identity()
    private init() { }
    
    var isLoggedIn: Bool {
        get {
            return user != nil
        }
    }
    
    var user: UserResult?
    
}
