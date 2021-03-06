
//
//  SearchResultVC.swift
//  e926
//
//  Created by Austin Chau on 10/9/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit

class SearchResultVC: UIViewController {
    
    var listVC: ListCollectionVC!
    
    var searchString: String?
    var searchStringCorrected: String? {
        return searchString?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        instantiateVC()
        
        self.title = searchString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.hidesBarsOnSwipe = true
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if navigationController?.isNavigationBarHidden == true {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
        navigationController?.hidesBarsOnSwipe = false
        super.viewWillDisappear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func instantiateVC() {
        listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        
        setupVC(vc: listVC)
        
        navigationController?.pushViewController(listVC, animated: false)
        
        listVC.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func setupVC(vc: ListCollectionVC) {
        //vdeletete = self
        //vc.collectionView?.contentInset = UIEdgeInsetsMake(64, 0, 40, 0)
        
    }
    
    func useE621ModeDidChange() {
        _ = navigationController?.popToViewController(listVC, animated: false)
        listVC.removeFromParentViewController()
        instantiateVC()
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
/*
extension SearchResultVC: ListCollectionVCRequestDelegate {
    internal func getResult(last_before_id: Int?) -> Promise<ListResult> {
        return ListRequester().downloadList(ofType: .post, formattedTags: searchStringCorrected, last_before_id: last_before_id)
    }

    internal func vcShouldLoadImmediately() -> Bool {
        return true
    }
}
*/
