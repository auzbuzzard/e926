//
//  Preferences.swift
//  E621
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import Foundation
import PromiseKit

enum Preferences: String {
    case useE621Mode
    case useStrongFilters
}

enum Store: String {
    case searchHistory
    
}

class SettingsStore {
    
}

class Censor {
    
    static var censorMode: CensorMode {
        let useE621Mode = UserDefaults.standard.bool(forKey: Preferences.useE621Mode.rawValue)
        let useStrongFilters = UserDefaults.standard.bool(forKey: Preferences.useStrongFilters.rawValue)
        if useStrongFilters { return .strong }
        if Identity.main.isLoggedIn && useE621Mode { return .none }
        else if Identity.main.isLoggedIn && !useE621Mode { return .safe }
        else if !Identity.main.isLoggedIn && useE621Mode { return .none }
        else {
            #if DEBUG
                return .safe
            #else
                return .strong
            #endif
        }
    }
    enum CensorMode { case strong, safe, none }
    
    static var bannedTagsPromise: Promise<Void>!
    static var bannedTags: [String] = ["underwear", "nude", "breasts", "partially_clothed", "cleavage", "featureless_crotch", "low_angle_view", "undressing","big_breasts", "skimpy", "obese", "crossdressing", "diaper", "young"]
    
    enum CensorError: Error {
        case cannotLoadFromPastebin
    }
}
