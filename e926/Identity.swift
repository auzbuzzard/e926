//
//  Identity.swift
//  E621
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire

class Identity {
    
    static let main = Identity()
    private init() { }
    
    static var censorMode: CensorMode {
        let useE621Mode = UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue)
        let useStrongFilters = UserDefaults.standard.bool(forKey: Preferences.useStrongFilters.rawValue)
        if useStrongFilters { return .strong }
        if main.isLoggedIn && useE621Mode { return .none }
        else if main.isLoggedIn && !useE621Mode { return .safe }
        else if !main.isLoggedIn && useE621Mode { return .none }
        else {
            #if DEBUG
                return .safe
            #else
                return .strong
            #endif
        }
    }
    enum CensorMode { case strong, safe, none }
    
    var apiKey: String?
    
    var isLoggedIn: Bool {
        get {
            return user != nil
        }
    }
    
    var user: UserResult?
    
    func signIn(email: String, password: String) {
        
    }
    
}

class LoginManager {
    
    func signInThroughForm(username: String, password: String) {
        //getAPIKey()
        let str = "https://e621.net/user/authenticate"
        let param = [
            "user[name]" : "anonymoushawk",
            "user[password]" : "tamedyiffyfoxxx"
        ]
        
        let request = Network.postWithAlamo(url: str, params: param, encoding: JSONEncoding.default)
        _ = request.response().then { response -> Void in
            print(response.1.allHeaderFields)
           // let data =
            
            let data = response.2
            let string = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
            print(string?.string)
            //self.getAPIKey()
        }
    }
    
    func getAPIKey() {
        let str = "https://e621.net/user/api_key"
        let param = [
            "user[name]" : "anonymoushawk",
            "user[password]" : "tamedyiffyfoxxx"
        ]
        let request = Network.postWithAlamo(url: str, params: param, encoding: JSONEncoding.default)
        _ = request.response().then { response -> Void in
            print(response)
            let data = response.2
            let string = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
            print(string?.string)
            //print(response)
        }
    }
    
}
