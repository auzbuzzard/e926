//
//  SearchTableVC.swift
//  e926
//
//  Created by Austin Chau on 6/10/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import UIKit

class SearchTableVC: UITableViewController {
    
    var dataSource: ListCollectionVM!
    
    var searchSuggestionsVC: SearchSuggestionsVC!
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ListCollectionVM()
        searchSuggestionsVC = storyboard?.instantiateViewController(withIdentifier: "searchSuggestionsVC") as! SearchSuggestionsVC
        setupSearchField()
    }
    
    func setupSearchField() {
        searchController = UISearchController(searchResultsController: searchSuggestionsVC)
        searchController.searchResultsUpdater = searchSuggestionsVC
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.barStyle = .black
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textField?.textColor = Theme.colors().text
        textField?.placeholder = "Search for Images"
        
        navigationItem.titleView = searchController.searchBar
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    func showResults(with stringTag: String?) {
        
        let listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        listVC.dataSource = dataSource
        listVC.listCategory = "Results"
        navigationController?.delegate = listVC
        listVC.isFirstListCollectionVC = true
        listVC.shouldHideNavigationBar = false
        dataSource.tags = dataSource.tags(from: stringTag ?? "")
        
        navigationController?.pushViewController(listVC, animated: true)
        listVC.title = dataSource.tags?.joined(separator: " ")
        
        
        dataSource.getResults(asNew: true, withTags: dataSource.tags, onComplete: {
            listVC.collectionView?.reloadData()
        })
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchResultVC" {
            if let vc = segue.destination as? SearchResultVC, let sender = sender as? UISearchBar  {
                vc.searchString = sender.text
            }
        }
    }

}

extension SearchTableVC: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    func searchControllerDidSelect(item: String) {
        searchController.searchBar.text = item
        searchController.dismiss(animated: true, completion: {
            
        })
    }
}

extension SearchTableVC: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.dismiss(animated: true, completion: {
            self.showResults(with: searchBar.text)
        })
        
    }
}

extension SearchTableVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            navigationController.setNavigationBarHidden(true, animated: animated)
            if navigationController.hidesBarsOnSwipe == true {
                navigationController.hidesBarsOnSwipe = false
            }
        } else {
            navigationController.setNavigationBarHidden(false, animated: animated)
            if let _ = viewController as? ListCollectionVC {
                navigationController.hidesBarsOnSwipe = true
                
            } else {
                if navigationController.hidesBarsOnSwipe == true {
                    navigationController.hidesBarsOnSwipe = false
                }
            }
        }
    }
}

