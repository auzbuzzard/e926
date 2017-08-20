//
//  ListCollectionVCMainCell.swift
//  e926
//
//  Created by Austin Chau on 8/20/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import UIKit
import PromiseKit
import Gifu

protocol ListCollectionVCMainCellDataSource {
    var artistsName: String { get }
    var authorName: String { get }
    var favCount: Int { get }
    var score: Int { get }
    var rating: ImageResult.Metadata.Rating { get }
    var imageType: ImageResult.Metadata.File_Ext { get }
    var mainImageData: Promise<Data> { get }
    var profileImageData: Promise<Data> { get }
}

class ListCollectionVCMainCell: UICollectionViewCell {
    
    var currentIndexPath: IndexPath!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelBkgdView: UIView!
    @IBOutlet weak var mainImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mainImageView.image = nil
        mainImageView.prepareForReuse()
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
        _ = dataSource.mainImageData.then { data -> Void in
            if indexPath == self.currentIndexPath {
                if dataSource.imageType == .gif {
                    self.mainImageView.animate(withGIFData: data)
                } else {
                    guard let image = UIImage(data: data) else { print("Image at \(indexPath) could not be casted into UIImage."); return }
                    self.mainImageView.image = image
                }
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
