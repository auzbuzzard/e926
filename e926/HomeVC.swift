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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeVC.useE621ModeDidChange), name: Notification.Name.init(rawValue: Preferences.useE621Mode.rawValue), object: nil)
        
        instantiateVC()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func instantiateVC() {
        listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        
        listVC.delegate = self
        
        setViewControllers([listVC], animated: false)
        
        listVC.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func useE621ModeDidChange() {
        listVC.getNewResult()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HomeVC: ListCollectionVCRequestDelegate {
    internal func vcShouldLoadImmediately() -> Bool {
        return true
    }
    
    func getResult(last_before_id: Int?) -> Promise<ListResult> {
        return ListRequester().downloadList(OfType: .post, tags: nil, last_before_id: last_before_id)
    }
}
