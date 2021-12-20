//
//  DebugMenuCell.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import UIKit

final class DebugMenuCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mainLabel: UILabel!
    
    var item: DebugMenuItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.masksToBounds = true
        containerView.layer.borderColor = UIColor.green.cgColor
        containerView.layer.cornerRadius = 6
    }
    
    func didSelect() {
        item.isSelected.toggle()
        containerView.layer.borderWidth = item.isSelected ? 3 : 0
        mainLabel.text = item.isSelected ?
        item.landmark.description.uppercased() :
        item.landmark.description.lowercased()
    }
    
    func configureWith(_ item: DebugMenuItem) {
        self.item = item
        mainLabel.text = item.landmark.description.capitalized
    }
}
