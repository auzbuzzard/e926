//
//  ListCollectionVC.swift
//  E621
//
//  Created by Austin Chau on 10/7/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit

private let reuseIdentifier = "mainCell"

protocol ListCollectionVCRequestDelegate {
    func getResult(results: ListResult?, completion: @escaping (ListResult) -> Void)
    func vcShouldLoadImmediately() -> Bool
}

class ListCollectionVC: UICollectionViewController {
    
    var delegate: ListCollectionVCRequestDelegate?
    var results: ListResult!
    
    var refresh = UIRefreshControl()
    var isLoading = false
    
    var isFirstListVC = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isFirstListVC {
            navigationController?.delegate = self
        }
        
        results = ListResult()
        
        if let delegate = delegate, delegate.vcShouldLoadImmediately(), !isLoading {
            getResult() { self.isLoading = false }
        }
        
        collectionView?.backgroundColor = Theme.colors().background
        
        refresh.addTarget(self, action: #selector(ListCollectionVC.getNewResult), for: .valueChanged)
        collectionView?.addSubview(refresh)
        
        // Add infinite scroll handler
        
        collectionView?.infiniteScrollIndicatorStyle = .whiteLarge
        collectionView?.addInfiniteScroll { [weak self] (scrollView) -> Void in
            let collectionView = scrollView
            
            // suppose this is an array with new data
            let currentResultCount = self?.results.results.count
            self?.getResult() {
                
                var indexPaths = [IndexPath]()
                //print(currentResultCount, self?.results.results.count)
                for n in currentResultCount! - 1...(self?.results.results.count)! - 1 {
                    let indexPath = IndexPath(row: n, section: 0)
                    //print(indexPath)
                    indexPaths.append(indexPath)
                }
                
                // create index paths for affected items
                
                // Update collection view
                collectionView.performBatchUpdates({ () -> Void in
                    // add new items into collection
                    //collectionView.insertItems(at: indexPaths)
                    }, completion: { (finished) -> Void in
                        // finish infinite scroll animations
                        collectionView.finishInfiniteScroll()
                })
                
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func getNewResult() {
        results = ListResult()
        //print(isLoading)
        if !isLoading {
            getResult() {
                DispatchQueue.main.async {
                    self.refresh.endRefreshing()
                }
            }
        }
    }
    
    func getResult(callback: @escaping () -> Void) {
        isLoading = true
        delegate?.getResult(results: results, completion: { _ in
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.isLoading = false
                callback()
            }
        })
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImageZoomVC" {
            let destinationVC = segue.destination as! ImageZoomVC
            let index = (sender as! IndexPath).row
            destinationVC.imageResult = results.results[index]
        }
     }
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.results.count ?? 0
    }
    
    @IBAction func segueTap(_ sender: UITapGestureRecognizer) {
        print("tapped")
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Define cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ListCollectionVCMainCell
        
        // Setup gesture recognizer
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ListCollectionVC.segueTapRecognizerIsTapped(sender:)))
        singleTap.numberOfTapsRequired = 1
        cell.mainImage.addGestureRecognizer(singleTap)
        
        // Add Corners
        if let windowWidth = view.window?.bounds.size.width {
            if cell.bounds.size.width < windowWidth  {
                cell.layer.cornerRadius = 5
            } else {
                cell.layer.cornerRadius = 0
            }
        }
        
        // Safeguard if there's enough cell
        guard indexPath.row < results.results.count else { return cell }
        
        // Define Item
        let item = results.results[indexPath.row]
        
        // Setting the cell
        let artists = item.metadata.artist?.joined(separator: ", ")
        cell.titleLabel.text = artists != "" ? artists : "(no artist)"
        cell.titleSubheading.text = item.metadata.author
        
        cell.footerFavLabel.text = "\(item.metadata.fav_count)"
        cell.footerScoreLabel.text = "\(item.metadata.score)"
        
        cell.mainImage.image = item.image(ofSize: .sample, fallBackSize: .preview, fallback: { success in
            if success {
                DispatchQueue.main.async {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        })
        
        // Getting the Avatar
        let user_id = item.metadata.creator_id
        if let user = UserRequester().get(userWithId: user_id, fallback: { success in
            if success {
                DispatchQueue.main.async {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }) {
            user.getAvatar(completion: {image, isSafe in
                if isSafe {
                    
                }
            })
        }
        
        // Setting the Footer
        let rating = item.metadata.rating
        var color = UIColor()
        if rating == "s" {
            color = Theme.colors().background_safe
        } else if rating == "q" {
            color = Theme.colors().background_questionable
        } else if rating == "e" {
            color = Theme.colors().background_explicit
        } else { color = Theme.colors().background }
        
        cell.titleView.backgroundColor = color
        cell.footerView.backgroundColor = color
        
        return cell
    }
    
    func segueTapRecognizerIsTapped(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let point:CGPoint = sender.location(in: collectionView)
            if let indexPath = collectionView?.indexPathForItem(at: point) {
                performSegue(withIdentifier: "showImageZoomVC", sender: indexPath)
            }
        }
        
    }
    
    func cellMainImageIsTapped(indexPath: IndexPath) {
        
    }
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    
    
}

extension ListCollectionVC: UINavigationControllerDelegate {
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

extension ListCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = view.window?.bounds.size.width ?? 375
        if width > 480 {
            width = 480
        }
        let itemMetadata = results.results[indexPath.row].metadata
        let imageHeight = itemMetadata.height(ofSize: .sample) ?? 400
        let imageWidth = itemMetadata.width(ofSize: .sample) ?? Int(width)
        let correctedImageHeight = width / CGFloat(imageWidth) * CGFloat(imageHeight)
        
        
        let height = 60 + 50 + correctedImageHeight
        //print("width: \(width), height: \(height)")
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1000
    }
}

class ListCollectionVCMainCell: UICollectionViewCell {
    
    var indexPath: IndexPath?
    
    @IBOutlet weak var titleView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var titleSubheading: UILabel!
    
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var footerView: UIView!
    
    @IBOutlet weak var footerScoreLabel: UILabel!
    @IBOutlet weak var footerFavLabel: UILabel!
    @IBOutlet weak var footerCommentLabel: UILabel!
    
    
    
}
