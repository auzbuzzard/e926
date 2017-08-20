//
//  ImageDetailVCTagCollection.swift
//  e926
//
//  Created by Austin Chau on 8/19/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import UIKit

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
