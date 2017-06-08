//
//  ViewModel.swift
//  e926
//
//  Created by Austin Chau on 6/6/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation

class FavoritesSearchTagsVM {
    static let defaultsKey = "WatchSearchSettingEntries"
    let defaults = UserDefaults(suiteName: "com.auzbuzzard.e926.defaults")!
    var entryCount: Int {
        return entries?.count ?? 0
    }
    var entries: NSMutableDictionary? {
        return defaults.object(forKey: FavoritesSearchTagsVM.defaultsKey) as? NSMutableDictionary
    }
    func entry(for index: Int) -> String? {
        guard let strings = defaults.object(forKey: FavoritesSearchTagsVM.defaultsKey) as? NSMutableDictionary else { return nil }
        return strings.value(forKey: "\(index)") as? String
    }
    func set(_ entry: String, at index: Int) {
        let strings: NSMutableDictionary = {
            if let result = defaults.object(forKey: FavoritesSearchTagsVM.defaultsKey) as? NSMutableDictionary, let copy = result.mutableCopy() as? NSMutableDictionary {
                return copy
            } else {
                return NSMutableDictionary()
            }
        }()
        strings.setValue(entry, forKeyPath: "\(index)")
        defaults.set(strings, forKey: FavoritesSearchTagsVM.defaultsKey)
    }
    func remove(entryAt index: Int) {
        guard let strings: NSMutableDictionary = {
            if let result = defaults.object(forKey: FavoritesSearchTagsVM.defaultsKey) as? NSMutableDictionary, let copy = result.mutableCopy() as? NSMutableDictionary {
                return copy
            } else { return nil }
            }() else { return }
        strings.removeObject(forKey: "\(index)")
        defaults.set(strings, forKey: FavoritesSearchTagsVM.defaultsKey)
    }
}
