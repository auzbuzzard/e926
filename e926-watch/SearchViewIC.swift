//
//  SearchViewIC.swift
//  e926
//
//  Created by Austin Chau on 6/6/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class SearchViewIC: WKInterfaceController {
    
    @IBOutlet var searchTermTable: WKInterfaceTable!
    var searches = [String]()
    let defaults = UserDefaults(suiteName: "com.auzbuzzard.e926.defaults")!
    
    // Mark: - View Life Cycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        WatchSession.shared.start()
        WCSession.default().sendMessage(["getStoredWatchSearchStrings":""], replyHandler: { reply in
            let entries = reply["returnStoredWatchSearchStrings"] as! NSMutableDictionary
            self.searchTermTable.setNumberOfRows(entries.count, withRowType: "searchTermRow")
        }, errorHandler: { _ in })
        //searchTermTable.setNumberOfRows(4, withRowType: "searchTermRow")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    // Mark: - Table
    
}
