//
//  MatrixNodeCell.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import UIKit

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

final class MatrixNodeCell: UICollectionViewCell {

    var node: MatrixNode! {
        didSet {
            contentView.layer.borderWidth = node.isGridHidden ? 0.0 : 0.2
            contentView.backgroundColor = node.painted
        }
    }

    override func awakeFromNib() {
        contentView.layer.borderColor = UIColor.blue.withAlphaComponent(0.4).cgColor
        contentView.layer.borderWidth = 0.2
    }
    
    func trigger() {
        contentView.layer.removeAllAnimations()
        contentView.backgroundColor = .random
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.contentView.backgroundColor = self.node.painted
        }, completion: nil)
    }
}
