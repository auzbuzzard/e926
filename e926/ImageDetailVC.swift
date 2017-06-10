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
    
    enum SectionType: Int { case tags = 0, statistics, comments }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        setupInfiniteScroll()
        tableView.beginInfiniteScroll(true)
        
        commentVM = ImageDetailCommentVM(post_id: imageResult.id)
    }
    
    func setupInfiniteScroll() {
        tableView.addInfiniteScroll { [weak self] tableView -> Void in
            let lastCount = (self?.commentVM.results.count)!
            self?.commentVM.getResults(page: nil, onComplete: {
                let currCount = (self?.commentVM.results.count)!
                print("\(currCount), \(lastCount)")
                tableView.setShouldShowInfiniteScrollHandler { _ -> Bool in
                    return currCount - lastCount != 0
                }
                var index = [IndexPath]()
                for n in lastCount..<currCount {
                    index.append(IndexPath(item: n, section: 2))
                }
                tableView.finishInfiniteScroll(completion: { (tableView) in
                    tableView.insertRows(at: index, with: .automatic)
                })
            })
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { return 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SectionType.tags.rawValue, SectionType.statistics.rawValue: return 1
        case SectionType.comments.rawValue: return commentVM.results.count
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
        label.textColor = .white
        switch section {
        case SectionType.tags.rawValue: label.text = "Tags"
        case SectionType.statistics.rawValue: label.text = "Statistics"
        case SectionType.comments.rawValue: label.text = "Comments"
        default: break
        }
        view.addSubview(label)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 44 }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            guard let tableViewCell = cell as? ImageDetailVCCollectionTextCell else { return }
            tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        default: break
        }
    }
    
    func open(withSearchTag tag: String) {
        let listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        listVC.dataSource = ListCollectionVM()
        listVC.listCategory = "Results"
        listVC.title = tag
        listVC.isFirstListCollectionVC = false
        navigationController?.pushViewController(listVC, animated: true)
        listVC.dataSource.getResults(asNew: true, withTags: [tag], onComplete: {
            listVC.collectionView?.reloadData()
        })
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
        collectionView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
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

class ImageDetailVCCommentCell: UITableViewCell {
    
    @IBOutlet weak var bkgdView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    func setupLayout() {
        bkgdView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        bkgdView.layer.cornerRadius = 10
        bkgdView.clipsToBounds = true
    }
    func setContent(comment: CommentResult) {
        nameLabel.text = comment.metadata.creator
        timeLabel.text = comment.metadata.created_at
        bodyTextView.text = comment.metadata.body
    }
}


