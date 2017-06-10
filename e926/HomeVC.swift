//
//  HomeVC.swift
//  E621
//
//  Created by Austin Chau on 10/7/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit
import Alamofire

class HomeVC: UINavigationController {
    
    var listVC: ListCollectionVC!
    var dataSource: ListCollectionVM!
    
    // Mark: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ListCollectionVM()
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeVC.useE621ModeDidChange), name: Notification.Name.init(rawValue: Preferences.useE621Mode.rawValue), object: nil)
        
        instantiateVC()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func instantiateVC() {
        listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        #if DEBUG
            print("HomeVC: Instantiating listVC: \(listVC)")
        #endif
        
        listVC.dataSource = dataSource
        listVC.listCategory = "Home"
        
        setViewControllers([listVC], animated: false)
        
        listVC.collectionView?.collectionViewLayout.invalidateLayout()
        
        dataSource.getResults(asNew: true, withTags: nil, onComplete: {
            self.listVC.collectionView?.reloadData()
        })
    }
    
    func useE621ModeDidChange() {
        dataSource.getResults(asNew: true, withTags: nil, onComplete: {
            self.listVC.collectionView?.reloadData()
        })
    }

}


