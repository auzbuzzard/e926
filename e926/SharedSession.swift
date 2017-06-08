//
//  SharedSession.swift
//  e926
//
//  Created by Austin Chau on 6/6/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSession: NSObject, WCSessionDelegate {
    #if os(iOS)
    @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    @available(iOS 9.3, *)
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    #endif
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    static let shared = WatchSession()
    private override init() { super.init() }
    
    private let session = WCSession.isSupported() ? WCSession.default() : nil
    #if os(iOS)
    private var validSession: WCSession? {
        if let session = session, session.isPaired, session.isWatchAppInstalled { return session }
        else { return nil }
    }
    private var validReachableSession: WCSession? {
        if let session = validSession, session.isReachable { return session }
        else { return nil }
    }
    #endif
    
    func start() {
        session?.delegate = self
        session?.activate()
    }
}
