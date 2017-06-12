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

protocol ListCollectionDataSource {
    var results: [ImageResult] { get }
    var tags: [String]? { get }
    var poolId: Int? { get }
    func getResults(asNew: Bool, withTags tags: [String]?, onComplete: @escaping () -> Void)
    func getPool(asNew: Bool, poolId: Int, onComplete: @escaping () -> Void)
}
struct ListCollectionDataSourceGetResultsOptions {
    enum OptionType { case tag, poolId }
    let optionType: OptionType
    var tags: [String]?
    var poolId: Int?
}
protocol ListCollectionDelegate {
    func listCollectionShouldHideNavBarOnList() -> Bool
}
extension ListCollectionDelegate {
    func listCollectionShouldHideNavBarOnList() -> Bool { return false }
}

/// There CollectionViewController class that deals with the vertical scroll view of lists of returned image results.
class ListCollectionVC: UICollectionViewController {
    
    // Mark: Delegates
    var dataSource: ListCollectionDataSource = ListCollectionVM()
    var listCategory: String?
    var isFirstListCollectionVC = false
    var shouldHideNavigationBar = true
    
    // Mark: VC Life Cycle
    private let cellReuseID = "mainCell"
    private let showImageSegueID = "showImageZoomVC"
    private let mainHeaderID = "mainHeader"
    fileprivate static let cellPadding = 30
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("LVC: \(dataSource is ListCollectionPoolVM)")
        setupRefreshControl()
        setupInfiniteScroll()
        if isFirstListCollectionVC {
            collectionView?.delegate = self
        }
        navigationController?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(useE621ModeDidChange), name: Notification.Name.init(rawValue: Preferences.useE621Mode.rawValue), object: nil)
    }
    
    func setupInfiniteScroll() {
        collectionView?.infiniteScrollIndicatorStyle = .whiteLarge
        collectionView?.addInfiniteScroll { [weak self] (scrollView) -> Void in
            let lastCount = (self?.dataSource.results.count)!
            //print(self?.dataSource)
            if self?.dataSource is ListCollectionVM {
                self?.dataSource.getResults(asNew: false, withTags: self?.dataSource.tags) {
                    self?.setupInfiniteScrollOnComplete(lastCount: lastCount, collectionView: scrollView)
                }
            } else if self?.dataSource is ListCollectionPoolVM {
                self?.dataSource.getPool(asNew: false, poolId: (self?.dataSource.poolId)!, onComplete: {
                    self?.setupInfiniteScrollOnComplete(lastCount: lastCount, collectionView: scrollView)
                })
            }
        }
    }
    private func setupInfiniteScrollOnComplete(lastCount: Int, collectionView scrollView: UICollectionView) {
        // Update collection view
        
        var index = [IndexPath]()
        for n in lastCount..<(self.dataSource.results.count) {
            index.append(IndexPath(item: n, section: 0))
        }
        //print("updating from inf scroll: \(index)")
        scrollView.performBatchUpdates({ () -> Void in
            scrollView.insertItems(at: index)
        }, completion: { (finished) -> Void in
            scrollView.finishInfiniteScroll()
        })
    }
    
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(ListCollectionVC.getNewResult), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
    }
    func getNewResult() {
        dataSource.getResults(asNew: true, withTags: dataSource.tags, onComplete: {
            self.collectionView?.reloadData()
            self.refreshControl.endRefreshing()
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Mark: - Segues
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
            let result = dataSource.results[index]
            destinationVC.imageResult = result
            DispatchQueue.global(qos: .background).async {
                for tag in result.metadata.tags_array {
                    _ = result.tagResult(from: tag).then { tagResult -> Void in
                        _ = TagCache.shared.setTag(tagResult)
                    }
                }
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return dataSource.results.count }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Define cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseID, for: indexPath) as! ListCollectionVCMainCell
        // Safeguard if there's enough cell
        guard indexPath.row < dataSource.results.count else { return cell }
        // Setup gesture recognizer
        cell.setupImageViewGesture(receiver: self)
        
        // Layout the cell
        if let windowWidth = view.window?.bounds.size.width {
            cell.setupCellLayout(windowWidth: windowWidth)
        }
        // Setting the cell
        let item = dataSource.results[indexPath.row]
        let itemVM = ListCollectionVCMainCellVM(imageResult: item)
        cell.setCellContents(indexPath: indexPath, dataSource: itemVM)
        
        // Done
        return cell
    }
    
    // Give section heading
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // if it's header
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: mainHeaderID, for: indexPath) as! ListCollectionVCMainHeader
            
            header.setContent(title: listCategory ?? "")
            return header
        } else {
            return UICollectionReusableView()
        }
    }
    
    // Mark: - UICollectionViewDelegate
    
    /*
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: showImageSegueID, sender: indexPath)
    }*/
    
    // Mark: - Notification Observing
    
    func useE621ModeDidChange() {
        dataSource.getResults(asNew: true, withTags: dataSource.tags, onComplete: {
            self.collectionView?.reloadData()
        })
    }
    
    // Mark: - Scroll View
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        //print("dragging")
        if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0 {
            changeTabBar(hidden: true, animated: true)
        } else {
            changeTabBar(hidden: false, animated: true)
        }
    }
    
    func changeTabBar(hidden:Bool, animated: Bool){
        let tabBar = self.tabBarController?.tabBar
        if tabBar!.isHidden == hidden { return }
        let frame = tabBar?.frame
        let offset = (hidden ? (frame?.size.height)! : -(frame?.size.height)!)
        let duration: TimeInterval = (animated ? 0.5 : 0.0)
        tabBar?.isHidden = false
        if frame != nil {
            UIView.animate(withDuration: duration, animations: {
                tabBar!.frame = tabBar!.frame.offsetBy(dx: 0, dy: offset)
            }, completion: {
                if $0 {
                    tabBar?.isHidden = hidden
                }
            })
        }
    }
}

// MARK: - Nav Controller Delegate

extension ListCollectionVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is ListCollectionVC {
            navigationController.setNavigationBarHidden(shouldHideNavigationBar, animated: animated)
            navigationController.hidesBarsOnSwipe = !shouldHideNavigationBar
        } else {
            navigationController.setNavigationBarHidden(false, animated: animated)
            navigationController.hidesBarsOnSwipe = false
        }
    }
}

// Mark: - CollectionView Flow Layout

extension ListCollectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = {
            var w = (view.window?.bounds.size.width ?? 375) - 30
            if w > 480 { w = 480 }
            return w
        }()
        
        guard indexPath.row < dataSource.results.count else { return CGSize(width: width, height: 0) }
        
        let itemMetadata = dataSource.results[indexPath.row].metadata
        let imageHeight = itemMetadata.height(ofSize: .sample) ?? 400
        let imageWidth = itemMetadata.width(ofSize: .sample) ?? Int(width)
        let correctedImageHeight = width / CGFloat(imageWidth) * CGFloat(imageHeight)
        
        
        let height = /*60 + 50 +*/ correctedImageHeight
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1000
    }
}

// Mark: CollectionView Cell Protocols

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

// Mark: - The CollectionView Cell

class ListCollectionVCMainCell: UICollectionViewCell {
    
    var currentIndexPath: IndexPath!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelBkgdView: UIView!
    @IBOutlet weak var mainImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mainImageView.image = nil
    }
    
    func setupImageViewGesture(receiver: ListCollectionVC) {
        let singleTap = UITapGestureRecognizer(target: receiver, action: #selector(receiver.segue(isTappedBy:)))
        singleTap.numberOfTapsRequired = 1
        mainImageView.addGestureRecognizer(singleTap)
        mainImageView.isUserInteractionEnabled = true
    }
    
    // Mark: - Actual filling in the data and layout
    
    func setupCellLayout(windowWidth: CGFloat) {
        contentView.layer.cornerRadius = bounds.size.width < windowWidth ? 10 : 10
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.backgroundColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 5
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        
    }
    
    func setCellContents(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        currentIndexPath = indexPath
        
        let ratingColor: UIColor = {
            switch dataSource.rating {
            case .s: return Theme.colors().background_safe
            case .q: return Theme.colors().background_questionable
            case .e: return Theme.colors().background_explicit
            }
        }()
        
        titleLabel.text = "\(dataSource.score) | \(dataSource.favCount)"
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        titleLabelBkgdView.layer.masksToBounds = true
        titleLabelBkgdView.layer.cornerRadius = titleLabelBkgdView.frame.size.height / 2
        titleLabelBkgdView.layer.backgroundColor = ratingColor.cgColor
        
        setMainImage(indexPath: indexPath, dataSource: dataSource)
    }
    
    func setMainImage(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        _ = dataSource.mainImage.then { image -> Void in
            if indexPath == self.currentIndexPath {
                self.mainImageView.image = image
            }
        }
    }
}

class ListCollectionVCMainHeader: UICollectionReusableView {
    
    @IBOutlet weak var mainHeaderLabel: UILabel!
    
    func setContent(title: String) {
        mainHeaderLabel.text = title
    }
    
}

