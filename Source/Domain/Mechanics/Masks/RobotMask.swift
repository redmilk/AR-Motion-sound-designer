//
//  RobotMask.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation
import UIKit.UIImage

enum ZoneKey: String, CaseIterable {
    case A = "AZone"
    case B = "BZone"
    case C = "CZone"
    case D = "DZone"
    case E = "EZone"
    case F = "FZone"
    case G = "GZone"
    case H = "HZone"
    case I = "IZone"
    case J = "JZone"
    case K = "KZone"
}

struct
SoundZone: Hashable {
    /// value sizes in collection nodes dimensions
    /// minX == minIndexPath.row
    /// maxY == maxIndexPath.section
    var minX: Int
    var maxX: Int
    var minY: Int
    var maxY: Int
    
    var centerPoint: CGPoint { CGPoint(x: max(1, (maxX - minX) / 2), y: max(1, (maxY - minY) / 2)) }
    var pointsAsList: [Int] { [minX, minY, maxX, maxY] }
    
    let title: String = ""
    
    func checkOverlapingBetweenZones(_ zone: SoundZone) -> Bool {
        let width = maxX - minX
        let height = maxY - minY
        return !zone.pointsAsList.filter { width...height ~= $0 }.isEmpty
    }
    
    func getAllIndexPathesInside() -> [IndexPath] {
        var indexPathList = [IndexPath]()
        for x in min(minX, maxX)...max(minX, maxX) {
            for y in min(minY, maxY)...max(minY, maxY) {
                indexPathList.append(IndexPath(row: x, section: y))
            }
        }
        return indexPathList
    }
    
    func validateTriggerConditionsWithIndexPath(_ indexPath: IndexPath) -> Bool {
        let x = indexPath.row
        let y = indexPath.section
        return min(minX, maxX)...max(minX, maxX) ~= x && min(minY, maxY)...max(minY, maxY) ~= y
    }
    
    func getCornersIndexPathList() -> [IndexPath] {
        [IndexPath(row: minX, section: minY), IndexPath(row: maxX, section: maxY)]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(minX)
        hasher.combine(maxX)
        hasher.combine(minY)
        hasher.combine(maxY)
        hasher.combine(title)
    }
}

struct ZoneValue {
    let icons: [UIImage]?
    let soundName: String
    let color: UIColor
}

class RobotMask: MaskBase {
    override init() {
        super.init()
        //let animationFrameDecoder = AnimationFrameDecoder()
        var zonePresets: [SoundZone: ZoneValue] = [:]
        
        let sound1Zone = SoundZone(minX: 3, maxX: 8, minY: 6, maxY: 11)
        let sound1Value = ZoneValue(icons: nil, soundName: "robotDry4", color: .random.withAlphaComponent(0.5))
        zonePresets[sound1Zone] = sound1Value
        
        let sound2Zone = SoundZone(minX: 12, maxX: 17, minY: 6, maxY: 11)
        let sound2Value = ZoneValue(icons: nil, soundName: "robotDry3", color: .random.withAlphaComponent(0.5))
        zonePresets[sound2Zone] = sound2Value
        
        let sound3Zone = SoundZone(minX: 21, maxX: 26, minY: 6, maxY: 11)
        let sound3Value = ZoneValue(icons: nil, soundName: "robotDry10", color: .random.withAlphaComponent(0.5))
        zonePresets[sound3Zone] = sound3Value
        
        let sound4Zone = SoundZone(minX: 5, maxX: 10, minY: 20, maxY: 30)
        let sound4Value = ZoneValue(icons: nil, soundName: "robotDry8", color: .random.withAlphaComponent(0.5))
        zonePresets[sound4Zone] = sound4Value
        
        let sound5Zone = SoundZone(minX: 25, maxX: 28, minY: 20, maxY: 22)
        let sound5Value = ZoneValue(icons: nil, soundName: "robotDry2", color: .random.withAlphaComponent(0.5))
        zonePresets[sound5Zone] = sound5Value
        
        let sound6Zone = SoundZone(minX: 10, maxX: 12, minY: 40, maxY: 42)
        let sound6Value = ZoneValue(icons: nil, soundName: "robotDry6", color: .random.withAlphaComponent(0.5))
        zonePresets[sound6Zone] = sound6Value
        
        let sound7Zone = SoundZone(minX: 25, maxX: 30, minY: 40, maxY: 55)
        let sound7Value = ZoneValue(icons: nil, soundName: "robotDry5", color: .random.withAlphaComponent(0.5))
        zonePresets[sound7Zone] = sound7Value
        
        self.zonePresets = zonePresets
    }
}
