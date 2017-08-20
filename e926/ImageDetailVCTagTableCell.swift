//
//  ImageDetailVCTagTableCell.swift
//  e926
//
//  Created by Austin Chau on 8/19/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import UIKit

class ImageDetailVCTagTableCell: UITableViewCell {
    static let storyboardID = "imageDetailVCTagTableCell"
    
    // Mark: - Properties
    @IBOutlet var collectionView: UICollectionView!
    
    func setupLayout() {
        collectionView.backgroundColor = Theme.colors().background_layer1.withAlphaComponent(0.5)
        collectionView.layer.cornerRadius = 5
        collectionView.layer.masksToBounds = true
    }
    
    // Mark: - Methods
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
