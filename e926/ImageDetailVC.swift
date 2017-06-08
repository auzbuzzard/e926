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
    var commentVM: ImageDetailCommentVM!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        setupInfiniteScroll()
        tableView.beginInfiniteScroll(true)
        
        commentVM = ImageDetailCommentVM(post_id: imageResult.id)
        /*commentVM.getResults(page: 1, onComplete: {
            self.tableView.reloadSections(IndexSet([2]), with: .automatic)
        })*/
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
        case 0, 1: return 1
        case 2: return commentVM.results.count
        default: return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! ImageDetailVCTextCell
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(tagIsTapped(sender:)))
            singleTap.numberOfTapsRequired = 1
            cell.mainTextView.addGestureRecognizer(singleTap)
            
            let tagAttrString = NSMutableAttributedString(string: imageResult.metadata.tags)
            tagAttrString.addAttribute(NSForegroundColorAttributeName, value: Theme.colors().text, range: NSMakeRange(0, tagAttrString.length))
            tagAttrString.addAttribute(NSFontAttributeName, value: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body), range: NSMakeRange(0, tagAttrString.length))
            
            cell.mainTextView.attributedText = tagAttrString
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! ImageDetailVCTextCell
            
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! ImageDetailVCCommentCell
            guard indexPath.row < commentVM.results.count else { break }
            cell.setContent(comment: commentVM.results[indexPath.row])
            
            return cell
            
        default: return UITableViewCell()
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Tags"
        case 1: return "Statistics"
        case 2: return "Comments"
        default: return nil
        }
    }
    

    func tagIsTapped(sender: UITapGestureRecognizer) {
        if let mainTextView = sender.view as? UITextView {
            let point = sender.location(in: mainTextView)
            let position = mainTextView.closestPosition(to: point)
            if let range = mainTextView.tokenizer.rangeEnclosingPosition(position!, with: .word, inDirection: 1) {
                
                var startIndex = mainTextView.offset(from: mainTextView.beginningOfDocument, to: range.start)
                var endIndex = mainTextView.offset(from: mainTextView.beginningOfDocument, to: range.end)
                
                //print("range: \(range)")
                
                //looking forwards
                
                //print("length: \(mainTextView.attributedText.length)")
                //print("ok: \(mainTextView.position(from: mainTextView.beginningOfDocument, offset: endIndex)), endIndex: \(endIndex), length: \(mainTextView.attributedText.length)")
                
                while true {
                    guard let _ = mainTextView.position(from: mainTextView.beginningOfDocument, offset: endIndex + 1) else {
                        endIndex -= 1
                        break
                    }
                    if endIndex >= mainTextView.attributedText.length {
                        endIndex = mainTextView.attributedText.length - 1
                        break
                    }
                    let endCharacter = mainTextView.attributedText.attributedSubstring(from: NSMakeRange(endIndex, 1))
                    //print("endIndex: \(endIndex), char: \(endCharacter.string)")
                    if endCharacter.string != " " && endIndex < mainTextView.attributedText.length - 1 {
                        endIndex += 1
                    } else {
                        endIndex -= 1
                        break
                    }
                }
                
                ////looking backwards
                
                while true {
                    guard let _ = mainTextView.position(from: mainTextView.beginningOfDocument, offset: startIndex - 1) else { break }
                    let startCharacter = mainTextView.attributedText.attributedSubstring(from: NSMakeRange(startIndex, 1))
                    //print("startIndex: \(startIndex), char: \(startCharacter.string)")
                    if startCharacter.string != " " && startIndex != 0 {
                        startIndex -= 1
                    } else {
                        startIndex += 1
                        break
                    }
                }
                
                //print("final: \(startIndex), \(endIndex - startIndex + 1)")
                
                let word = mainTextView.attributedText.attributedSubstring(from: NSMakeRange(startIndex, endIndex - startIndex + 1))
                
                //print("word: \(word.string), word length: \(word.length)")
                
                open(withSearchTag: word.string)
            }
        }
    }
    
    func open(withSearchTag tag: String) {
        let listVC = storyboard?.instantiateViewController(withIdentifier: "listCollectionVC") as! ListCollectionVC
        listVC.dataSource = ListCollectionVM()
        listVC.title = tag
        navigationController?.pushViewController(listVC, animated: true)
        listVC.dataSource.getResults(asNew: true, withTags: [tag], onComplete: {
            listVC.collectionView?.reloadData()
        })
    }

}

class ImageDetailVCTextCell: UITableViewCell {
    
    @IBOutlet weak var mainTextView: UITextView!
    
    
}

class ImageDetailVCCommentCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    func setContent(comment: CommentResult) {
        nameLabel.text = comment.metadata.creator
        timeLabel.text = comment.metadata.created_at
        bodyTextView.text = comment.metadata.body
    }
}


