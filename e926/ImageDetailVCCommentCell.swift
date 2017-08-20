//
//  ImageDetailVCCommentCell.swift
//  e926
//
//  Created by Austin Chau on 8/19/17.
//  Copyright © 2017 Austin Chau. All rights reserved.
//

import UIKit


class ImageDetailVCCommentCell: UITableViewCell {
    
    @IBOutlet weak var bkgdView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var bodyTextView: UITextView!
    
    func setupLayout() {
        bkgdView.backgroundColor = Theme.colors().background_layer1.withAlphaComponent(0.5)
        bkgdView.layer.cornerRadius = 10
        bkgdView.clipsToBounds = true
    }
    func setContent(comment: CommentResult) {
        nameLabel.text = comment.metadata.creator
        timeLabel.text = comment.metadata.created_at
        bodyTextView.text = comment.metadata.body
    }
}
