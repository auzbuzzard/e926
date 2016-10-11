//
//  Theme.swift
//  E621
//
//  Created by Austin Chau on 10/8/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit

enum Colors: Int {
    case basic = 1
    
    var background: UIColor { return UIColor(red: 21/255, green: 47/255, blue: 86/255, alpha: 1) }
    var background_layer1: UIColor { return UIColor(red: 40/255, green: 74/255, blue: 129/255, alpha: 1) }
    
    var background_safe: UIColor { return UIColor(red: 235/255, green: 245/255, blue: 236/255, alpha: 1) }
    var background_questionable: UIColor { return UIColor(red: 251/255, green: 251/255, blue: 230/255, alpha: 1) }
    var background_explicit: UIColor { return UIColor(red: 252/255, green: 239/255, blue: 239/255, alpha: 1) }
    
    var label_safe: UIColor { return UIColor(red: 62/255, green: 158/255, blue: 73/255, alpha: 1) }
    var label_questionable: UIColor { return UIColor(red: 228/255, green: 225/255, blue: 80/255, alpha: 1) }
    var label_explicit: UIColor { return UIColor(red: 228/255, green: 95/255, blue: 95/255, alpha: 1) }
    
    var text: UIColor { return UIColor.white }
    var link: UIColor { return UIColor(red: 180/255, green: 199/255, blue: 217/255, alpha: 1) }
}

struct Theme {
    static func colors() -> Colors {
        return .basic
    }
    
    static func apply() {
        UIApplication.shared.statusBarStyle = .lightContent
        UITabBar.appearance().barTintColor = colors().background
        UITabBar.appearance().tintColor = colors().link
        UIApplication.shared.statusBarView?.backgroundColor = colors().background
        
        UINavigationBar.appearance().barTintColor = colors().background
        UINavigationBar.appearance().tintColor = colors().link
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : Theme.colors().text]
        
        UITableView.appearance().backgroundColor = colors().background
        UITableViewCell.appearance().backgroundColor = colors().background_layer1
        
        //UILabel.appearance().textColor = colors().text
        
        UICollectionView.appearance().backgroundColor = colors().background
        
    }
}

extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}


