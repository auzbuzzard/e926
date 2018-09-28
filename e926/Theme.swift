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
    var yellow_highlight: UIColor { return UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)}
    
    var background_safe: UIColor { return UIColor(red: 62/255, green: 158/255, blue: 73/255, alpha: 1) }
    var background_questionable: UIColor { return UIColor(red: 228/255, green: 225/255, blue: 80/255, alpha: 1) }
    var background_explicit: UIColor { return UIColor(red: 228/255, green: 95/255, blue: 95/255, alpha: 1) }
    
    var background_safe_light: UIColor { return UIColor(red: 235/255, green: 245/255, blue: 236/255, alpha: 1) }
    var background_questionable_light: UIColor { return UIColor(red: 251/255, green: 251/255, blue: 230/255, alpha: 1) }
    var background_explicit_light: UIColor { return UIColor(red: 252/255, green: 239/255, blue: 239/255, alpha: 1) }
    
    var label_safe: UIColor { return UIColor(red: 62/255, green: 158/255, blue: 73/255, alpha: 1) }
    var label_questionable: UIColor { return UIColor(red: 228/255, green: 225/255, blue: 80/255, alpha: 1) }
    var label_explicit: UIColor { return UIColor(red: 228/255, green: 95/255, blue: 95/255, alpha: 1) }
    
    var upv: UIColor { return UIColor(red: 62/255, green: 158/255, blue: 73/255, alpha: 1) }
    var dnv: UIColor { return UIColor(red: 228/255, green: 95/255, blue: 95/255, alpha: 1) }
    
    var text: UIColor { return UIColor.white }
    var link: UIColor { return UIColor(red: 180/255, green: 199/255, blue: 217/255, alpha: 1) }
    func tagColor(ofType type: TagResult.Metadata.TypeEnum) -> UIColor {
        switch type {
        case .general: return UIColor(red: 180/255, green: 199/255, blue: 217/255, alpha: 1)
        case .artist: return UIColor(red: 242/255, green: 172/255, blue: 8/255, alpha: 1)
        case .copyright: return UIColor(red: 221/255, green: 0/255, blue: 221/255, alpha: 1)
        case .character: return UIColor(red: 0/255, green: 170/255, blue: 0/255, alpha: 1)
        case .species: return UIColor(red: 237/255, green: 93/255, blue: 31/255, alpha: 1)
        }
    }
}

struct Theme {
    static func colors() -> Colors {
        return .basic
    }
    
    static func apply(_ theme: Colors) {
        // Tab Bar
            // Remove top gradient line
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
        UITabBar.appearance().tintColor = theme.link
        UITabBar.appearance().barTintColor = theme.background
        // Navigation Bar
        UINavigationBar.appearance().barTintColor = theme.background_layer1
        UINavigationBar.appearance().tintColor = theme.text
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : theme.text]
        if #available(iOS 11, *) {
            UINavigationBar.appearance().largeTitleTextAttributes = [NSForegroundColorAttributeName : theme.text]
        }
        // Table View
        UITableView.appearance().backgroundColor = theme.background
        UITableViewCell.appearance().backgroundColor = theme.background
        // Collection View
        UICollectionView.appearance().backgroundColor = theme.background
        // Tool Bar
        UIToolbar.appearance().barTintColor = theme.background_layer1
        UIToolbar.appearance().tintColor = theme.text
        // UI Buttons
        UILabel.appearance().textColor = theme.text
        UITextField.appearance().tintColor = theme.link
        UITextView.appearance().tintColor = theme.link
        
        UISwitch.appearance().tintColor = theme.yellow_highlight
    }
}

extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

