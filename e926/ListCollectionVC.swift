//
//  ListCollectionVC.swift
//  E621
//
//  Created by Austin Chau on 10/7/16.
//  Copyright © 2016 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit
import UIScrollView_InfiniteScroll
import SwiftGifOrigin

protocol ListCollectionVCRequestDelegate {
    func vcShouldLoadImmediately() -> Bool
}

/// There CollectionViewController class that deals with the vertical scroll view of lists of returned image results.
class ListCollectionVC: UICollectionViewController {
    
    // Mark: Delegates
    var vm: ListCollectionVMProtocol!
    
    // Mark: VC Life Cycle
    private let cellReuseID = "mainCell"
    private let showImageSegueID = "showImageZoomVC"
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Infinite Scroll
        setupRefreshControl()
        setupInfiniteScroll()
    }
    
    func setupInfiniteScroll() {
        collectionView?.infiniteScrollIndicatorStyle = .whiteLarge
        collectionView?.addInfiniteScroll { [weak self] (scrollView) -> Void in
            let lastCount = (self?.vm.results.count)!
            self?.vm.getResults(asNew: false, withTags: self?.vm.tags) {
                // Update collection view
                var index = [IndexPath]()
                for n in lastCount..<(self?.vm.results.count)! {
                    index.append(IndexPath(item: n, section: 0))
                }
                scrollView.performBatchUpdates({ () -> Void in
                    scrollView.insertItems(at: index)
                }, completion: { (finished) -> Void in
                    scrollView.finishInfiniteScroll()
                })
            }
        }
    }
    
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(ListCollectionVC.getNewResult), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
    }
    func getNewResult() {
        vm.getResults(asNew: true, withTags: vm.tags, onComplete: {
            self.collectionView?.reloadData()
            self.refreshControl.endRefreshing()
        })
    }
    
    // Mark: Segues
    func segue(isTappedBy sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let point = sender.location(in: collectionView)
            if let indexPath = collectionView?.indexPathForItem(at: point) {
                performSegue(withIdentifier: showImageSegueID, sender: indexPath)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showImageSegueID {
            let destinationVC = segue.destination as! ImageZoomVC
            let index = (sender as! IndexPath).row
            destinationVC.imageResult = vm.results[index]
        }
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vm?.results.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Define cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseID, for: indexPath) as! ListCollectionVCMainCell
        // Safeguard if there's enough cell
        guard indexPath.row < vm.results.count else { return cell }
        // Setup gesture recognizer
        cell.setupImageViewGesture(receiver: self)
        
        // Add Corners
        if let windowWidth = view.window?.bounds.size.width {
            cell.setCellRadius(windowWidth: windowWidth)
        }

        // Setting the cell
        let item = vm.results[indexPath.row]
        let itemVM = ListCollectionVCMainCellVM(imageResult: item)
        cell.setCellContents(indexPath: indexPath, dataSource: itemVM)
        
        // Done
        return cell
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
        let width: CGFloat = {
            var w = view.window?.bounds.size.width ?? 375
            if w > 480 { w = 480 }
            return w
        }()
        
        guard indexPath.row < vm.results.count else { return CGSize(width: width, height: 0) }
        
        let itemMetadata = vm!.results[indexPath.row].metadata
        let imageHeight = itemMetadata.height(ofSize: .sample) ?? 400
        let imageWidth = itemMetadata.width(ofSize: .sample) ?? Int(width)
        let correctedImageHeight = width / CGFloat(imageWidth) * CGFloat(imageHeight)
        
        
        let height = 60 + 50 + correctedImageHeight
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1000
    }
}

// Mark: ViewCell Stuff

protocol ListCollectionVCMainCellDataSource {
    var artistsName: String { get }
    var authorName: String { get }
    var favCount: Int { get }
    var score: Int { get }
    var rating: ImageResult.Metadata.Rating { get }
    var imageType: ImageResult.Metadata.File_Ext { get }
    var mainImage: Promise<UIImage> { get }
    var profileImage: Promise<UIImage> { get }
}

struct ListCollectionVCMainCellVM: ListCollectionVCMainCellDataSource {
    let imageResult: ImageResult
    
    init(imageResult: ImageResult) {
        self.imageResult = imageResult
    }
    
    var artistsName: String { return imageResult.metadata.artist?.joined(separator: ", ") ?? "(no artist)" }
    var authorName: String { return imageResult.metadata.author }
    var favCount: Int { return imageResult.metadata.fav_count }
    var score: Int { return imageResult.metadata.score }
    var rating: ImageResult.Metadata.Rating { return imageResult.metadata.rating_enum }
    
    var imageType: ImageResult.Metadata.File_Ext { return imageResult.metadata.file_ext_enum ?? .jpg }
    var mainImage: Promise<UIImage> {
        return imageResult.image(ofSize: .sample)
    }
    var profileImage: Promise<UIImage> {
        return Promise<UIImage>(error: UserResult.UserResultError.noAvatarId(userId: 0))
    }
}

class ListCollectionVCMainCell: UICollectionViewCell {
    
    var currentIndexPath: IndexPath!
    
    @IBOutlet weak var titleView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var titleSubheading: UILabel!
    
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var footerView: UIView!
    
    @IBOutlet weak var footerScoreLabel: UILabel!
    @IBOutlet weak var footerFavLabel: UILabel!
    @IBOutlet weak var footerCommentLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mainImage.image = nil
        titleImage.image = nil
    }
    
    func setupImageViewGesture(receiver: ListCollectionVC) {
        let singleTap = UITapGestureRecognizer(target: receiver, action: #selector(ListCollectionVC.segue(isTappedBy:)))
        singleTap.numberOfTapsRequired = 1
        mainImage.addGestureRecognizer(singleTap)
    }
    
    func setCellRadius(windowWidth: CGFloat) {
        layer.cornerRadius = bounds.size.width < windowWidth ? 5 : 0
    }
    
    func setCellContents(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        currentIndexPath = indexPath
        titleLabel.text = dataSource.artistsName
        titleSubheading.text = dataSource.authorName
        footerFavLabel.text = "\(dataSource.favCount)"
        footerScoreLabel.text = "\(dataSource.score)"
        
        let color: UIColor = {
            switch dataSource.rating {
            case .s: return Theme.colors().background_safe
            case .q: return Theme.colors().background_questionable
            case .e: return Theme.colors().background_explicit
            }
        }()
        titleView.backgroundColor = color
        footerView.backgroundColor = color
        
        setMainImage(indexPath: indexPath, dataSource: dataSource)
        //setProfileImage(indexPath: indexPath, dataSource: dataSource)
    }
    
    func setMainImage(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        _ = dataSource.mainImage.then { image -> Void in
            if indexPath == self.currentIndexPath {
                self.mainImage.image = image
            }
        }
    }
    
    func setProfileImage(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        _ = dataSource.profileImage.then { image -> Void in
            if indexPath == self.currentIndexPath {
                self.titleImage.image = image
            }
        }
    }
}

/*
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
            getResult {
                self.isLoading = false
            }
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
        if !isLoading {
            getResult() {
                DispatchQueue.main.async {
                    self.refresh.endRefreshing()
                }
            }
        }
    }
    
    func getResult(completion: @escaping () -> Void) {
        isLoading = true
        delegate?.getResult(last_before_id: results.last_before_id).then { result -> Void in
            self.results.add(result)
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.isLoading = false
                completion()
            }
            }.catch { error in
                
        }
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
        
        cell.mainImage.image = nil
        
        item.imageFromCache(size: .sample)
            .recover { error -> Promise<UIImage> in
                return item.imageFromCache(size: .preview)
            }.then { image -> Void in
                cell.mainImage.image = image
            }.catch { error in
                if case ImageCache.CacheError.noImageInStore(_) = error {
                    item.downloadImage(ofSize: .sample)
                        .then { _ -> Void in
                            collectionView.reloadItems(at: [indexPath])
                        }.catch { error -> Void in
                    }
                } else {
                    
                }
        }
        
        // Getting the Avatar
        if let creator = item.creator {
            creator.avatarFromCache()
                .then { image in
                    cell.titleImage.image = image
                }.catch { error in
                    if case Cache.CacheError.noImageInStore(_) = error {
                        creator.getAvatar()
                            .then { _ in
                                collectionView.reloadItems(at: [indexPath])
                            }.catch { error in
                        }
                    }
            }
        } else {
            let user_id = item.metadata.creator_id
            UserRequester().getUser(WithId: user_id)
                .then { user -> Void in
                    item.creator = user
                    collectionView.reloadItems(at: [indexPath])
                }.catch { error in
                    
            }
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
*/
