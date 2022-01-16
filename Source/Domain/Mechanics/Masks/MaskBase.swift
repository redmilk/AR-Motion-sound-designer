//
//  MaskBase.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 12.01.2022.
//

import Foundation
import UIKit.UIColor

protocol MaskProtocol {
    var zonePresets: [SoundZone: ZoneValue] { get }
    var backgroundFileName: String? { get }
    func determinateSoundForZonesWithIndexPath(_ indexPath: IndexPath) -> String?
    func determinateIndexPathZoneColor(_ indexPath: IndexPath) -> UIColor?
}

class MaskBase: MaskProtocol {
    var zonePresets: [SoundZone: ZoneValue] = [:] {
        didSet {
            Logger.log("Total zones: \(zonePresets.count)", type: .grid)
            zonePresets.forEach { (zone, zoneValue) in
                //print("minY: \(zone.minY), maxY: \(zone.maxY), minX: \(zone.minX), maxX: \(zone.maxX). Color: \(zoneValue.zoneColor.debugDescription)")
            }
        }
    }
    var backgroundFileName: String?
    
    func determinateSoundForZonesWithIndexPath(_ indexPath: IndexPath) -> String? {
        var soundFileName: String?
        Set(zonePresets.keys).forEach {
            if $0.validateTriggerConditionsWithIndexPath(indexPath) {
                soundFileName = zonePresets[$0]?.soundName
                return
            }
        }
        return soundFileName
    }
    
    func determinateIndexPathZoneColor(_ indexPath: IndexPath) -> UIColor? {
        var color: UIColor?
        Set(zonePresets.keys).forEach {
            if $0.validateTriggerConditionsWithIndexPath(indexPath) {
                color = zonePresets[$0]?.zoneColor
                return
            }
        }
        return color
    }
}
