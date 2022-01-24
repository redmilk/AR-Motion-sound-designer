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
    private var isForSounds: Bool { item.soundForZone != nil }
    
    var item: DebugMenuItem! {
        didSet {
            /// resolve what to display
            /// landmarks for detector or sound names
            mainLabel.text = item.soundForZone?.replacingOccurrences(of: ".wav", with: "") ?? item.landmark.description.capitalized
            containerView.layer.borderWidth = !isForSounds && item.isSelected ? 3 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.masksToBounds = true
        containerView.layer.borderColor = UIColor.green.cgColor
        containerView.layer.cornerRadius = 6
        containerView.layer.borderWidth = 0
    }
    
    func didSelect() {
        item.isSelected.toggle()
        containerView.layer.borderWidth = item.isSelected ? 3 : 0
    }
    
    func animateSelection() {
        containerView.layer.removeAllAnimations()
        let initialcolor = containerView.backgroundColor
        containerView.backgroundColor = .random
        UIView.animate(withDuration: 1.5, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.containerView.backgroundColor = initialcolor
        }, completion: nil)
    }
}
