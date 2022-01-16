//
//  Mask64Mapper.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 23.12.2021.
//

import Foundation
import UIKit.UIColor

struct Mask64Mapper {
    private let rowsCount: Int = 8
    private let linesCount: Int = 16
    
    private let lineWidth = 1
    private let rowWidth = 1
    
    private let rowSpacing: Int = 2
    private let lineSpacing: Int = 2
    
    private let topPadding: Int = 10
    private let leftPadding: Int = 1
    
    func makeMask64() -> Mask64SoundsDemo {
        var zonePresets: [SoundZone: ZoneValue] = [:]
        var prevLineY: Int?
        var counter = 0
        for line in 0...linesCount - 1 {
            var y = line + lineWidth + (prevLineY ?? 1) + lineSpacing
            prevLineY = y - line
            if line == 0 {
                prevLineY = topPadding
                y = topPadding
            }
            var prevRowX: Int?
            for row in 0...rowsCount - 1 {
                var x = row + rowWidth + (prevRowX ?? 1) + rowSpacing
                prevRowX = x - row
                if row == 0 {
                    prevRowX = leftPadding
                    x = leftPadding
                }
                let soundZone = SoundZone(
                    minX: x, maxX: x + rowWidth, minY: y, maxY: y + lineWidth)
                counter += 1
                if counter == 63 {
                    counter = 0
                }
                let soundNameStr = counter >= 10 ?
                counter.description : "0\(counter)"
                let soundValue = ZoneValue(icons: nil, soundName: soundNameStr)
                zonePresets[soundZone] = soundValue
            }
            prevRowX = nil
        }
        return Mask64SoundsDemo(zonePresets: zonePresets)
    }
}

struct Mask64SoundsDemo: MaskProtocol {
    var zonePresets: [SoundZone: ZoneValue]
    let backgroundFileName: String? = nil
    
    init() {
        let zonePresets: [SoundZone: ZoneValue] = [:]
        self.zonePresets = zonePresets
    }
    
    init(zonePresets: [SoundZone: ZoneValue]) {
        self.init()
        self.zonePresets = zonePresets
    }
    
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
