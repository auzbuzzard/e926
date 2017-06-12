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
    
    @IBAction func openInSafari(_ sender: UIBarButtonItem) {
        let u = ImageRequester.image_url + "/\(imageResult.id)"
        let url = URL(string: u)
        let svc = SFSafariViewController(url: url!, entersReaderIfAvailable: false)
        svc.delegate = self
        self.present(svc, animated: true, completion: nil)
    }
    var imageResult: ImageResult!
    var tags = [TagResult]()
    var commentVM: ImageDetailCommentVM!
    var poolVM: ListCollectionPoolVM!
    
    var imageHasPool = false
    
    enum SectionType: Int { case tags = 0, statistics = -1, pool = 1, comments = 2 }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        
        setupInfiniteScroll()
        tableView.beginInfiniteScroll(true)
        
        //findIfImageHasPool()
        poolVM = ListCollectionPoolVM()
        poolVM.getPool(asNew: true, forImage: imageResult.id) {
            //print("got results")
            let i = IndexSet(integer: SectionType.pool.rawValue)
            self.tableView.reloadSections(i , with: UITableViewRowAnimation.automatic)
        }
        commentVM = ImageDetailCommentVM(post_id: imageResult.id)
    }
    
    func setupInfiniteScroll() {
        tableView.addInfiniteScroll { [weak self] tableView -> Void in
            let lastCount = (self?.commentVM.results.count)!
            self?.commentVM.getResults(page: nil, onComplete: {
                let currCount = (self?.commentVM.results.count)!
                //print("\(currCount), \(lastCount)")
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
            })
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
        switch section {
        case SectionType.tags.rawValue, SectionType.pool.rawValue: return 1
        case SectionType.comments.rawValue: return commentVM.results.count
        case SectionType.statistics.rawValue: fallthrough
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case SectionType.tags.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "collectionTextCell", for: indexPath) as! ImageDetailVCCollectionTextCell
            cell.setupLayout()
            cell.layoutIfNeeded()
            return cell
        case SectionType.statistics.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! ImageDetailVCTextCell
            
            return cell
        case SectionType.pool.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "poolSimpleCell", for: indexPath)
            cell.textLabel?.textColor = Theme.colors().text
            cell.textLabel?.text = poolVM.result?.metadata.name
            //cell.setupLayout()
            //cell.setupContents(poolVM: poolVM)
            //cell.layoutIfNeeded()
            
            return cell
            
        case SectionType.comments.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! ImageDetailVCCommentCell
            guard indexPath.row < commentVM.results.count else { break }
            cell.setupLayout()
            cell.setContent(comment: commentVM.results[indexPath.row])
            
            return cell
            
        default: return UITableViewCell()
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: tableView.frame.size.width - 8, height: 32))
        label.font = UIFont.systemFont(ofSize: 26, weight: UIFontWeightMedium)
        label.textColor = Theme.colors().text
        switch section {
        case SectionType.tags.rawValue: label.text = "Tags"
        //case SectionType.statistics.rawValue: label.text = "Statistics"
        case SectionType.pool.rawValue: label.text = "Pool"
        case SectionType.comments.rawValue: label.text = "Comments"
        default: break
        }
        view.addSubview(label)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return section == SectionType.pool.rawValue ? 72 : 44 }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            guard let tableViewCell = cell as? ImageDetailVCCollectionTextCell else { return }
            tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        default: break
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("selected something: \(indexPath)")
        switch indexPath.section {
        case SectionType.pool.rawValue:
            //print("Pool table clicked")
            if poolVM.result != nil {
                //print("opening pool")
                open(withPool: poolVM)
            } else { /*print("fallthru");*/ fallthrough }
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func open(withSearchTag tag: String) {
        let listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        listVC.dataSource = ListCollectionVM()
        listVC.listCategory = "Results"
        listVC.title = tag
        listVC.isFirstListCollectionVC = false
        listVC.shouldHideNavigationBar = false
        navigationController?.pushViewController(listVC, animated: true)
        listVC.dataSource.getResults(asNew: true, withTags: [tag], onComplete: {
            listVC.collectionView?.reloadData()
        })
    }
    func open(withPool vm: ListCollectionPoolVM) {
        //print("poolVM: \(poolVM.results.count)")
        let listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        listVC.dataSource = poolVM
        listVC.listCategory = "Pool"
        listVC.title = vm.result?.metadata.name
        listVC.isFirstListCollectionVC = false
        listVC.shouldHideNavigationBar = false
        navigationController?.pushViewController(listVC, animated: true)
        listVC.collectionView?.reloadData()
    }
}

extension ImageDetailVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeLabel = UILabel()
        sizeLabel.text = imageResult.metadata.tags.components(separatedBy: " ")[indexPath.row]
        sizeLabel.sizeToFit()
        
        return CGSize(width: sizeLabel.bounds.width + 16, height: 24)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

extension ImageDetailVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageResult.metadata.tags.components(separatedBy: " ").count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tokenCell", for: indexPath) as! ImageDetailVCCollectionTextCellCollectionCell
        
        let tags =  imageResult.metadata.tags.components(separatedBy: " ")
        cell.setupCellLayout()
        cell.setupCellContents(tag: tags[indexPath.row], result: imageResult) {
            //collectionView.reloadItems(at: [indexPath])
            cell.layoutIfNeeded()
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = imageResult.metadata.tags.components(separatedBy: " ")[indexPath.row]
        open(withSearchTag: tag)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 10, 10, 10)
    }
}

class ImageDetailVCTextCell: UITableViewCell {
    @IBOutlet weak var mainTextView: UITextView!
}

class ImageDetailVCCollectionTextCell: UITableViewCell {
    @IBOutlet var collectionView: UICollectionView!
    
    func setupLayout() {
        collectionView.backgroundColor = Theme.colors().background_layer1.withAlphaComponent(0.5)
        collectionView.layer.cornerRadius = 5
        collectionView.layer.masksToBounds = true
    }
    
    func setCollectionViewDataSourceDelegate(_ delegate: UICollectionViewDelegate & UICollectionViewDataSource, forRow row: Int) {
        collectionView.delegate = delegate
        collectionView.dataSource = delegate
        collectionView.tag = row
        collectionView.reloadData()
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        collectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(10000))
        collectionView.layoutIfNeeded()
        return collectionView.collectionViewLayout.collectionViewContentSize
    }
}

class ImageDetailVCCollectionTextCellCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    func setupCellContents(tag: String, result: ImageResult, onComplete: @escaping () -> Void) {
        label.text = tag
        label.backgroundColor = Theme.colors().tagColor(ofType: .general)
        self.label.sizeToFit()
        self.contentView.setNeedsLayout()
        _ = result.tagResult(from: tag).then { tagResult -> Void in
            self.label.backgroundColor = Theme.colors().tagColor(ofType: tagResult.metadata.type_enum)
            onComplete()
        }
    }
    func setupCellLayout() {
        contentView.layer.cornerRadius = bounds.size.height / 2
        contentView.layer.masksToBounds = true
    }
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

class ImageDetailVCCommentCell: UITableViewCell {
    
    @IBOutlet weak var bkgdView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    func setupLayout() {
        bkgdView.backgroundColor = Theme.colors().background_layer1.withAlphaComponent(0.5)
        bkgdView.layer.cornerRadius = 10
        bkgdView.clipsToBounds = true
    }
    func setContent(comment: CommentResult) {
        nameLabel.text = comment.metadata.creator
        timeLabel.text = comment.metadata.created_at
        bodyTextView.text = comment.metadata.body
    }
}


