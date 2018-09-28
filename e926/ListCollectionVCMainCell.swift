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
    enum Errors: Error {
        case imageTypeNotSupported(indexPath: IndexPath)
    }
    
    static let storyboardID = "listCollectionVCMainCell"
    
    var currentIndexPath: IndexPath!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelBkgdView: UIView!
    @IBOutlet weak var mainImageView: UIImageView!
    
    lazy var label = UILabel()
    lazy var fileTypeWarningView = UIImageView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.removeFromSuperview()
        fileTypeWarningView.removeFromSuperview()
        mainImageView.stopAnimatingGIF()
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
    
    func setupCellLayout(dataSource: ListCollectionVCMainCellDataSource, windowWidth: CGFloat) {
        contentView.backgroundColor = Theme.colors().background_layer1
        
        contentView.layer.cornerRadius = bounds.size.width < windowWidth ? 10 : 10
        contentView.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.backgroundColor = UIColor.clear.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 5
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        
        titleLabel.textColor = Theme.colors().text
        titleLabelBkgdView.layer.masksToBounds = true
        titleLabelBkgdView.layer.cornerRadius = titleLabelBkgdView.frame.size.height / 2
        
        let ratingColor: UIColor = {
            switch dataSource.rating {
            case .s: return Theme.colors().background_safe
            case .q: return Theme.colors().background_questionable
            case .e: return Theme.colors().background_explicit
            }
        }()
        titleLabelBkgdView.layer.backgroundColor = ratingColor.cgColor
    }
    
    func setCellContents(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        currentIndexPath = indexPath
        
        // titleLabel
        let titleString = NSMutableAttributedString()
        
        titleString.append(NSAttributedString(string: {
            switch dataSource.score {
            case _ where dataSource.score > 0: return "⬆︎\(dataSource.score)"
            case _ where dataSource.score < 0: return "⬇︎\(dataSource.score)"
            default: return "⬆︎⬇︎\(dataSource.score)"
            }
        }(), attributes: [NSForegroundColorAttributeName: {
                switch dataSource.score {
                //case _ where dataSource.score > 0: return Theme.colors().upv
                //case _ where dataSource.score < 0: return Theme.colors().dnv
                default: return Theme.colors().text
                }
            }()]
        ))
        titleString.append(NSAttributedString(string: " | ", attributes: [NSForegroundColorAttributeName: Theme.colors().text]))
        titleString.append(NSAttributedString(string: "♥︎\(dataSource.favCount)", attributes: [NSForegroundColorAttributeName: Theme.colors().text]))
        
        titleLabel.attributedText = titleString
        titleLabel.sizeToFit()
        
        // Check filetype
        if dataSource.imageType == .webm || dataSource.imageType == .swf {
            setFileTypeWarningImage(dataSource)
        }
        
        setMainImage(indexPath: indexPath, dataSource: dataSource)
    }
    
    func setMainImage(indexPath: IndexPath, dataSource: ListCollectionVCMainCellDataSource) {
        dataSource.mainImageData.then { data -> Void in
            if indexPath == self.currentIndexPath {
                if dataSource.imageType == .gif {
                    self.mainImageView.prepareForAnimation(withGIFData: data)
                    self.mainImageView.startAnimatingGIF()
                } else {
                    guard let image = UIImage(data: data) else { throw  Errors.imageTypeNotSupported(indexPath: indexPath) }
                    self.mainImageView.image = image
                }
            }
        }.catch { error in
            switch error {
            case ImageResult.Errors.imageTypeNotSupported(_), Errors.imageTypeNotSupported(_):
                break
            default: print(error)
            }
        }
    }
    
    func animateImage() {
        self.mainImageView.startAnimatingGIF()
    }
    
    // MARK: - Internal methods
    
    fileprivate func setFileTypeWarningImage(_ dataSource: ListCollectionVCMainCellDataSource) {
        fileTypeWarningView.image = dataSource.imageType == .webm ? #imageLiteral(resourceName: "webm") : #imageLiteral(resourceName: "swf")
        contentView.addSubview(fileTypeWarningView)
        fileTypeWarningView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints([
            NSLayoutConstraint(item: fileTypeWarningView, attribute: .centerX, relatedBy: .equal, toItem: mainImageView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: fileTypeWarningView, attribute: .centerY, relatedBy: .equal, toItem: mainImageView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: fileTypeWarningView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: mainImageView.bounds.width * 0.3),
            NSLayoutConstraint(item: fileTypeWarningView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: mainImageView.bounds.width * 0.3)
            ])
    }
}

class ListCollectionVCMainHeader: UICollectionReusableView {
    
    @IBOutlet weak var mainHeaderLabel: UILabel!
    
    func setContent(title: String) {
        mainHeaderLabel.text = title
    }
    
}
