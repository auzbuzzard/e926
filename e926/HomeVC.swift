//
//  HomeVC.swift
//  E621
//
//  Created by Austin Chau on 10/7/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

class HomeVC: UINavigationController {
    
    var listVC: ListCollectionVC!
    var vm: ListCollectionVM!
    
    // Mark: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        vm = ListCollectionVM()
        
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
        
        listVC.vm = vm
        
        setViewControllers([listVC], animated: false)
        
        listVC.collectionView?.collectionViewLayout.invalidateLayout()
        
        vm.getResults(asNew: true, withTags: nil, onComplete: {
            self.listVC.collectionView?.reloadData()
        })
    }
    
    func useE621ModeDidChange() {
        vm.getResults(asNew: true, withTags: nil, onComplete: { })
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
