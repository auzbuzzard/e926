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
    
    var background_safe: UIColor { return UIColor(red: 62/255, green: 158/255, blue: 73/255, alpha: 1) }
    var background_questionable: UIColor { return UIColor(red: 228/255, green: 225/255, blue: 80/255, alpha: 1) }
    var background_explicit: UIColor { return UIColor(red: 228/255, green: 95/255, blue: 95/255, alpha: 1) }
    
    var background_safe_light: UIColor { return UIColor(red: 235/255, green: 245/255, blue: 236/255, alpha: 1) }
    var background_questionable_light: UIColor { return UIColor(red: 251/255, green: 251/255, blue: 230/255, alpha: 1) }
    var background_explicit_light: UIColor { return UIColor(red: 252/255, green: 239/255, blue: 239/255, alpha: 1) }
    
    var label_safe: UIColor { return UIColor(red: 62/255, green: 158/255, blue: 73/255, alpha: 1) }
    var label_questionable: UIColor { return UIColor(red: 228/255, green: 225/255, blue: 80/255, alpha: 1) }
    var label_explicit: UIColor { return UIColor(red: 228/255, green: 95/255, blue: 95/255, alpha: 1) }
    
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
    
    static func apply() {
        let color = colors().background.withAlphaComponent(0.98)
        let imageColor = UIImage(color: color)
        // Status Bar
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.statusBarView?.backgroundColor = color
        // Tab Bar
        UITabBar.appearance().backgroundImage = imageColor
        UITabBar.appearance().tintColor = colors().link
        // Navigation Bar
        UINavigationBar.appearance().tintColor = colors().link
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : Theme.colors().text]
        UINavigationBar.appearance().setBackgroundImage(imageColor, for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        // Table View
        UITableView.appearance().backgroundColor = colors().background
        UITableViewCell.appearance().backgroundColor = .clear
        // Collection View
        UICollectionView.appearance().backgroundColor = colors().background
        
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

