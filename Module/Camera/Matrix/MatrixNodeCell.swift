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
        containerView.layer.borderColor = UIColor.yellow.cgColor
        containerView.layer.borderWidth = 0.5
        containerView.layer.masksToBounds = true
    }
    
    func trigger() {
        containerView.backgroundColor = .yellow
        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.containerView.backgroundColor = .clear
        })
    }
}
