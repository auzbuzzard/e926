 //
 //  SearchVC.swift
 //  E621
 //
 //  Created by Austin Chau on 10/8/16.
 //  Copyright © 2016 Austin Chau. All rights reserved.
 //
 
 import UIKit
 import PromiseKit
 
 class SearchVC: UIViewController {
    
    var dataSource: ListCollectionVM!
    
    var searchController: UISearchController!
    var searchBar: UISearchBar { get { return searchController.searchBar } }
    var searchSuggestionsVC: SearchSuggestionsVC!
    
    @IBOutlet weak var searchViewHolder: UIView!
    
    @IBAction func segueWithSearch(segue: UIStoryboardSegue) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = ListCollectionVM()
        view.backgroundColor = Theme.colors().background
        navigationController?.delegate = self
        searchSuggestionsVC = storyboard?.instantiateViewController(withIdentifier: "searchSuggestionsVC") as! SearchSuggestionsVC
        setupSearchBar()
        NotificationCenter.default.addObserver(self, selector: #selector(SearchVC.useE621ModeDidChange), name: Notification.Name.init(rawValue: Preferences.useE621Mode.rawValue), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchController.searchBar.sizeToFit()
        searchController.searchBar.frame.size.width = self.view.frame.size.width
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchResultVC" {
            if let vc = segue.destination as? SearchResultVC, let sender = sender as? UISearchBar  {
                vc.searchString = sender.text
            }
        }
    }
    
    //Mark: Results
    
    var listVC: ListCollectionVC!
    
    func showResults(with stringTag: String?) {
        
        listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        listVC.dataSource = dataSource
        listVC.listCategory = "Results"
        listVC.isFirstListCollectionVC = false
        dataSource.tags = dataSource.tags(from: stringTag ?? "")
        
        navigationController?.pushViewController(listVC, animated: true)
        listVC.title = dataSource.tags?.joined(separator: " ")
        
        //listVC.collectionView?.collectionViewLayout.invalidateLayout()
        dataSource.getResults(asNew: true, withTags: dataSource.tags, onComplete: {
            self.listVC.collectionView?.reloadData()
        })
    }
    
    // Mark: SearchBar
    
    func setupSearchBar() {
        searchController = UISearchController(searchResultsController: searchSuggestionsVC)
        
        let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = Theme.colors().text
        
        searchController.delegate = self
        
        searchBar.delegate = self
        
        searchController.searchResultsUpdater = searchSuggestionsVC
        
        searchViewHolder.addSubview(searchBar)
        searchBar.searchBarStyle = .minimal
        searchBar.keyboardAppearance = .dark
        searchBar.returnKeyType = .search
        
        definesPresentationContext = false
    }
    
    func useE621ModeDidChange() {
        dataSource.getResults(asNew: true, withTags: dataSource.tags, onComplete: { })
    }
 }
 
 extension SearchVC: UISearchControllerDelegate {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            searchController.searchResultsController?.view.isHidden = false
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    func searchControllerDidSelect(item: String) {
        searchBar.text = item
        searchController.dismiss(animated: true, completion: {
            
        })
    }
    
 }
 
 extension SearchVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.dismiss(animated: true, completion: { })
        showResults(with: searchBar.text)
    }
    
    
    
 }
 
 extension SearchVC: UINavigationControllerDelegate {
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
