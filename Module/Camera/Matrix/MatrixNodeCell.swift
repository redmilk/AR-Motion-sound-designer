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

    @IBOutlet weak var containerView: UIView!
    var node: MatrixNode? {
        didSet {
            guard let node = node else { return }
            containerView.layer.borderWidth = node.isGridHidden ? 0.0 : 0.2 
        }
    }

    override func awakeFromNib() {
        containerView.layer.borderColor = UIColor.blue.withAlphaComponent(0.6).cgColor
        containerView.layer.borderWidth = 0.2
        containerView.layer.masksToBounds = true
    }
    
    func trigger() {
        containerView.layer.removeAllAnimations()
        containerView.backgroundColor = .random
        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.containerView.backgroundColor = .clear
        })
    }
}
