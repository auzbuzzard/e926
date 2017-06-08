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
        navigationController?.delegate = self
        
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

extension HomeVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            navigationController.setNavigationBarHidden(true, animated: animated)
        } else if let _ = viewController as? ListCollectionVC {
            navigationController.hidesBarsOnSwipe = true
        } else {
            navigationController.setNavigationBarHidden(false, animated: animated)
            if navigationController.hidesBarsOnSwipe == true {
                navigationController.hidesBarsOnSwipe = false
            }
        }
    }
}

/*
extension HomeVC: ListCollectionVCRequestDelegate {
    internal func vcShouldLoadImmediately() -> Bool {
        return true
    }
    
    func getResult(last_before_id: Int?) -> Promise<ListResult> {
        return ListRequester().downloadList(ofType: .post, tags: nil, last_before_id: last_before_id)
    }
}
*/
