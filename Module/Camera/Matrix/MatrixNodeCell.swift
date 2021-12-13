//
//  MatrixNodeCell.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import UIKit

final class MatrixNodeCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    var node: MatrixNode?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.layer.borderColor = UIColor.black.cgColor
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.masksToBounds = true
    }
    
    func trigger() {
        containerView.backgroundColor = .black
        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.containerView.backgroundColor = .yellow
        })
    }
}
