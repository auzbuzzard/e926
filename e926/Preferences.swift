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
}

enum Store: String {
    case searchHistory
    
}

class SettingsStore {
    
}

class Censor {
    
    static var bannedTagsPromise: Promise<Void>!
    static var bannedTags: [String] = ["underwear", "nude", "breasts", "partially_clothed", "cleavage", "featureless_crotch", "low_angle_view", "undressing","big_breasts", "skimpy", "obese", "crossdressing", "diaper", "young"]
    
    enum CensorError: Error {
        case cannotLoadFromPastebin
    }
}
