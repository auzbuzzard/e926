//
//  ImageDetailVC.swift
//  e926
//
//  Created by Austin Chau on 10/10/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import SafariServices

class ImageDetailVC: UITableViewController, SFSafariViewControllerDelegate {
    // Mark: - Declarations
    
    enum SectionType: Int { case tags = 0, statistics = -1, pool = 1, comments = 2 }
    
    // Mark: - Properties
    
    var imageResult: ImageResult!
    var tags = [TagResult]()
    var commentVM: ImageDetailCommentVM!
    var poolVM: ListCollectionPoolVM!
    
    var imageHasPool = false
    
    // Mark: - VC Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        
        setupInfiniteScroll()
        tableView.beginInfiniteScroll(true)
        
        //findIfImageHasPool()
        poolVM = ListCollectionPoolVM()
        poolVM.getPool(asNew: true, forImage: imageResult.id).then { () -> Void in
            //print("got results")
            let i = IndexSet(integer: SectionType.pool.rawValue)
            self.tableView.reloadSections(i , with: UITableViewRowAnimation.automatic)
        }.catch { print($0) }
        commentVM = ImageDetailCommentVM(post_id: imageResult.id)
    }
    
    func setupInfiniteScroll() {
        tableView.addInfiniteScroll { [weak self] tableView -> Void in
            let lastCount = (self?.commentVM.results.count)!
            self?.commentVM.getResults(page: nil).then { () -> Void in
                let currCount = (self?.commentVM.results.count)!
                print("\(currCount), \(lastCount)")
                tableView.setShouldShowInfiniteScrollHandler { _ -> Bool in
                    return currCount - lastCount != 0
                }
                var index = [IndexPath]()
                for n in lastCount..<currCount {
                    index.append(IndexPath(item: n, section: SectionType.comments.rawValue))
                }
                tableView.finishInfiniteScroll(completion: { (tableView) in
                    tableView.insertRows(at: index, with: .automatic)
                })
            }.catch { print($0) }
        }
    }
    /*
    func findIfImageHasPool() -> Promise<PoolResult> {
        PoolRequester().getPool(forImage: imageResult.id).then {
            self.imageHasPool = true
            
        }
    }*/

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { return 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = SectionType(rawValue: section) else { return 0 }
        switch sectionType {
        case .tags, .pool: return 1
        case .comments: return commentVM.results.count
        case .statistics: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = SectionType(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .tags:
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageDetailVCTagTableCell.storyboardID, for: indexPath) as! ImageDetailVCTagTableCell
            cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 10000) // Forcing the tableview cell to go over so that autolayout will work
            cell.setupLayout()
            cell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)

            return cell
            
        case .statistics:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! ImageDetailVCTextCell
            return cell
            
        case .pool:
            let cell = tableView.dequeueReusableCell(withIdentifier: "poolSimpleCell", for: indexPath)
            cell.textLabel?.textColor = Theme.colors().text
            cell.textLabel?.text = poolVM.result?.metadata.name
            //cell.setupLayout()
            //cell.setupContents(poolVM: poolVM)
            //cell.layoutIfNeeded()
            return cell
            
        case .comments:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! ImageDetailVCCommentCell
            guard indexPath.row < commentVM.results.count else { break }
            cell.setupLayout()
            cell.setContent(comment: commentVM.results[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: tableView.frame.size.width - 8, height: 32))
        label.font = UIFont.systemFont(ofSize: 26, weight: UIFontWeightMedium)
        label.textColor = Theme.colors().text
        
        if let sectionType = SectionType(rawValue: section) {
            switch sectionType {
            case .tags: label.text = "Tags"
            case .statistics: break //label.text = "Statistics"
            case .pool: label.text = "Pool"
            case .comments: label.text = "Comments"
            }
        }
        
        view.addSubview(label)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return SectionType(rawValue: section) == .pool ? 72 : 44 }
    
    /*override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let section = SectionType(rawValue: indexPath.section) else { return }
        switch section {
        case .tags:
            guard let tableViewCell = cell as? ImageDetailVCCollectionTextCell else { return }
            tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        default: break
        }
    }*/
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected something: \(indexPath)")
        guard let section = SectionType(rawValue: indexPath.section) else { return }
        switch section {
        case .pool:
            print("Pool table clicked")
            if poolVM.result != nil {
                print("opening pool")
                open(with: poolVM)
            } else { print("fallthru"); fallthrough }
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // Mark: - Actions
    
    @IBAction func openInSafari(_ sender: UIBarButtonItem) {
        let u = ImageRequester.image_url + "/\(imageResult.id)"
        let url = URL(string: u)
        let svc = SFSafariViewController(url: url!, entersReaderIfAvailable: false)
        svc.delegate = self
        if #available(iOS 10, *) {
            svc.preferredBarTintColor = Theme.colors().background_layer1
            svc.preferredControlTintColor = Theme.colors().text
        }
        self.present(svc, animated: true, completion: nil)
    }
    
    func open(with searchTag: String) {
        SearchManager.main.appendSearch(SearchManager.SearchHistory(timeStamp: Date(), searchString: searchTag))
        
        let listVC = UIStoryboard(name: ListCollectionVC.storyboardName, bundle: nil).instantiateViewController(withIdentifier: ListCollectionVC.storyboardID) as! ListCollectionVC
        listVC.dataSource = ListCollectionVM(result: ListResult())
        listVC.listCategory = "Results"
        listVC.title = searchTag
        listVC.isFirstListCollectionVC = false
        listVC.shouldHideNavigationBar = false
        navigationController?.pushViewController(listVC, animated: true)
        listVC.dataSource?.getResults(asNew: true, withTags: [searchTag]).then {
            listVC.collectionView?.reloadData()
        }.catch { print($0) }
    }
    func open(with poolVM: ListCollectionPoolVM) {
        print("poolVM: \(poolVM.results.count)")
        let listVC = UIStoryboard(name: ListCollectionVC.storyboardName, bundle: nil).instantiateViewController(withIdentifier: ListCollectionVC.storyboardID) as! ListCollectionVC
        listVC.dataSource = poolVM
        listVC.listCategory = "Pool"
        listVC.title = poolVM.result?.metadata.name
        listVC.isFirstListCollectionVC = false
        listVC.shouldHideNavigationBar = false
        navigationController?.pushViewController(listVC, animated: true)
        listVC.collectionView?.reloadData()
    }
}

class ImageDetailVCTextCell: UITableViewCell {
    @IBOutlet weak var mainTextView: UITextView!
}



class ImageDetailVCPoolCell: UITableViewCell {
    @IBOutlet weak var bkgdView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    func setupLayout() {
        bkgdView.backgroundColor = Theme.colors().background_layer1.withAlphaComponent(0.5)
        bkgdView.layer.cornerRadius = 10
        bkgdView.clipsToBounds = true
        label.textColor = Theme.colors().text
    }
    func setupContents(poolVM: ListCollectionPoolVM) {
        label.text = poolVM.result?.metadata.name
    }
    
}



