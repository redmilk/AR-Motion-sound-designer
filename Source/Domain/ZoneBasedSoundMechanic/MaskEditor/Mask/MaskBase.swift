//
//  MaskBase.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 12.01.2022.
//

import Foundation
import UIKit.UIColor
import MLKit

protocol MaskProtocol {
    var zonePresets: [SoundZone: ZoneValue] { get }
    var backgroundFileName: String? { get }
    func determinateSoundForZonesWithIndexPath(_ indexPath: IndexPath) -> String?
    func determinateIndexPathZoneColor(_ indexPath: IndexPath) -> UIColor?
}

extension PoseLandmarkType: Codable { }

class MaskBase: MaskProtocol, Codable {
    var zonePresets: [SoundZone: ZoneValue] = [:]
    
    var totalNumberOfZones: Int { zonePresets.count }
    var totalNumberOfUniqueSounds: Int { Set(zonePresets.values.map { $0.soundName }).count }
    var backgroundFileName: String?
    var landmarksForMask: [PoseLandmarkType]?
    var shouldForcaplaySounds: Bool = true
    var forcePlayingSoundFilenames = ["": true]
    var createdWith: String?

    init(zonePresets: [SoundZone: ZoneValue] = [:], createdWith: String? = nil) {
        self.zonePresets = zonePresets
        self.createdWith = createdWith
    }
    
    func determinateSoundForZonesWithIndexPath(_ indexPath: IndexPath) -> String? {
        var soundFileName: String?
        zonePresets.keys.forEach {
            if $0.validateTriggerConditionsWithIndexPath(indexPath) {
                soundFileName = zonePresets[$0]?.soundName
                return
            }
        }
        return soundFileName
    }
    
    func determinateIndexPathZoneColor(_ indexPath: IndexPath) -> UIColor? {
        var color: UIColor?
        zonePresets.keys.forEach {
            if $0.validateTriggerConditionsWithIndexPath(indexPath) {
                color = zonePresets[$0]?.color
                return
            }
        }
        return color
    }
    
    func determinateZone(with indexPath: IndexPath) -> [SoundZone: ZoneValue]? {
        var zone: [SoundZone: ZoneValue]?
        for (key, value) in zonePresets {
            if key.validateTriggerConditionsWithIndexPath(indexPath) {
                zone = [key: value]
                break
            }
        }
        return zone
    }
}
