//
//  InterfaceController.swift
//  e926-watch Extension
//
//  Created by Austin Chau on 12/21/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var feedTable: WKInterfaceTable!
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
