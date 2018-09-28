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

protocol ListCollectionDataSource {
    var results: [ImageResult] { get }
    var tags: [String]? { get }
    var poolId: Int? { get }
    func getResults(asNew: Bool, withTags tags: [String]?) -> Promise<Void>
    func getPool(asNew: Bool, poolId: Int) -> Promise<Void>
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
    
    // MARK: - Declarations
    
    enum Errors: Error {
        case setupInfiniteScrollFailed
    }
    
    // MARK: - Constants and tags
    public static let storyboardName = "ListCollection"
    public static let storyboardID = "listCollectionVC"
    private let showImageSegueID = "showImageZoomVC"
    private let mainHeaderID = "mainHeader"
    
    var isFirstListCollectionVC = false
    var shouldHideNavigationBar = true
    
    fileprivate static let cellPadding = 30
    
    // Mark: - Delegates
    var dataSource: ListCollectionDataSource?
    var listCategory: String?
    
    // Mark: - VC Life Cycle
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRefreshControl()
        setupInfiniteScroll()
        
        navigationController?.delegate = self
        if #available(iOS 11, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
        }
        if isFirstListCollectionVC {
            navigationItem.rightBarButtonItems = nil
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(useE621ModeDidChange), name: Notification.Name.init(rawValue: Preferences.useE621Mode.rawValue), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Setup UI
    
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(ListCollectionVC.getNewResult), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
    }
    
    func setupInfiniteScroll() {
        collectionView?.infiniteScrollIndicatorStyle = .whiteLarge
        collectionView?.addInfiniteScroll { [weak self] (scrollView) -> Void in
            firstly { () -> Promise<(Void, Int)> in
                // Setup loading when performing infinite scroll
                guard let lastCount = self?.dataSource?.results.count,
                    let dataSource = self?.dataSource else { return Promise(error: Errors.setupInfiniteScrollFailed) }
                if dataSource is ListCollectionVM {
                    return dataSource.getResults(asNew: false, withTags: dataSource.tags).then { return ($0, lastCount) }
                } else if dataSource is ListCollectionPoolVM {
                    return dataSource.getPool(asNew: false, poolId: dataSource.poolId!).then { return ($0, lastCount) }
                } else { return Promise(error: Errors.setupInfiniteScrollFailed) }
            }.then { (_, lastCount) -> Void in
                // Update collection view
                guard let dataSource = self?.dataSource else { throw Errors.setupInfiniteScrollFailed }
                var index = [IndexPath]()
                for n in lastCount..<dataSource.results.count {
                    index.append(IndexPath(item: n, section: 0))
                }
                scrollView.performBatchUpdates({ () -> Void in
                    scrollView.insertItems(at: index)
                }, completion: { (finished) -> Void in
                    scrollView.finishInfiniteScroll()
                })
            }.catch { error in print(error) }
        }
    }
    
    func getNewResult() {
        dataSource?.getResults(asNew: true, withTags: dataSource?.tags).then { () -> Void in
            self.collectionView?.reloadData()
            self.refreshControl.endRefreshing()
        }.catch { print($0) }
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
            let result = dataSource?.results[index]
            destinationVC.imageResult = result
            DispatchQueue.global(qos: .background).async {
                guard let result = result else { return }
                for tag in result.metadata.tags_array {
                    _ = result.tagResult(from: tag).then { tagResult -> Void in
                        _ = TagCache.shared.setTag(tagResult)
                    }
                }
            }
        }
    }
    
    // Mark: - Notification Observing
    
    func useE621ModeDidChange() {
        dataSource?.getResults(asNew: true, withTags: dataSource?.tags).then {
            self.collectionView?.reloadData()
        }.catch { print($0) }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return dataSource?.results.count ?? 0 }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Define cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListCollectionVCMainCell.storyboardID, for: indexPath) as! ListCollectionVCMainCell
        // Guard if dataSource exists
        guard let dataSource = dataSource else { return cell }
        // Safeguard if there's enough cell
        guard indexPath.row < dataSource.results.count else { return cell }
        // Setup gesture recognizer
        cell.setupImageViewGesture(receiver: self)
        
        // Setting and Layout the cell
        let item = dataSource.results[indexPath.row]
        let itemVM = ListCollectionVCMainCellVM(imageResult: item)
        cell.setupCellLayout(dataSource: itemVM, windowWidth: view.window?.bounds.width ?? view.bounds.width)
        cell.setCellContents(indexPath: indexPath, dataSource: itemVM)
        
        // Done
        return cell
    }
}

// MARK: - Nav Controller Delegate

extension ListCollectionVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is ListCollectionVC {
            navigationController.setNavigationBarHidden(false, animated: animated)
            //navigationController.hidesBarsOnSwipe = !shouldHideNavigationBar
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
        
        guard let dataSource = dataSource, indexPath.row < dataSource.results.count else { return CGSize(width: width, height: 0) }
        
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






