//
//  HitTester.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 11.12.2021.
//

import Foundation
import UIKit

/// Conditions validator
/// Could be mixed with other validations
/// f.e. Action recognition + Pose detection
protocol HitTestValidationStrategy {
    func validateConditions() -> Bool
}

struct ZoneTriggerHitTest: HitTestValidationStrategy {
    var zone: SoundZone
    var indexPath: IndexPath
    
    init(zone: SoundZone, indexPath: IndexPath) {
        self.zone = zone
        self.indexPath = indexPath
    }
    
    func validateConditions() -> Bool {
        let x = indexPath.row
        let y = indexPath.section
        
        return zone.minX...zone.maxX ~= x && zone.minY...zone.maxY ~= y
    }
}
