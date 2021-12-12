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
    var zone: CGRect
    var dot: CGPoint
    
    init(zone: CGRect, dot: CGPoint) {
        self.zone = zone
        self.dot = dot
    }
    
    func validateConditions() -> Bool {
        dot.x >= zone.minX &&
        dot.x <= zone.maxX &&
        dot.y >= zone.minY &&
        dot.y <= zone.maxY
    }
}
