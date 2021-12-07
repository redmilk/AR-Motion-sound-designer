//
//  AdjustVolumeView.swift
//  Jiggle
//
//  Created by Павло Сливка on 28.10.2021.
//  Copyright © 2021 Google Inc. All rights reserved.
//

import UIKit

class AdjustVolumeView: UIView{
    
    var delegate: VolumeValuesDelegate?

    @IBOutlet private var volumeSlider: UISlider! {
        didSet {
            volumeSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
        }
    }
    @IBAction func volumeChanged(_ sender: Any) {
    }
    
    func start() {
        if let volume = delegate?.getVolumeAtStart() {
            volumeSlider.value = volume
        }

        translatesAutoresizingMaskIntoConstraints = false
        if let superview = superview {
            NSLayoutConstraint.activate([
                       topAnchor.constraint(equalTo: superview.topAnchor),
                       bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                       leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                       trailingAnchor.constraint(equalTo: superview.trailingAnchor),
                   ])
        }
    }
    
    func end() {
        delegate?.setVolumeAtFinish(newVolume: volumeSlider.value)
        
        self.removeFromSuperview()
    }
}
