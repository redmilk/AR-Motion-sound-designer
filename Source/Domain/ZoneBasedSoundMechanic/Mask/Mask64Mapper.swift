//
//  Mask64Mapper.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 23.12.2021.
//

import Foundation
import UIKit.UIColor

struct Mask64Mapper {
    
    enum SoundsTotal {
        case sounds32
        case sounds32equal
        case sounds32x2
        case sounds32x2rowSpacing
        case sounds32fillScreen
        case sounds64
        case sounds64fillScreen
        case sounds64x2
        case sounds64x2fillScreen
    }
    
    var rowsCount: Int!
    var linesCount: Int!
    
    var lineWidth: Int!
    var rowWidth: Int!
    
    var rowSpacing: Int!
    var lineSpacing: Int!
    
    var topPadding: Int!
    var leftPadding: Int!
    
    init(type: SoundsTotal) {
        switch type {
        case .sounds32equal:
            rowsCount = 4
            linesCount = 8
            lineWidth = 4
            rowWidth = 3
            rowSpacing = 4
            lineSpacing = 4
            topPadding = 2
            leftPadding = 2
        case .sounds32:
            rowsCount = 4
            linesCount = 8
            lineWidth = 5
            rowWidth = 4
            rowSpacing = 4
            lineSpacing = 3
            topPadding = 2
            leftPadding = 0
        case .sounds32x2:
            rowsCount = 4
            linesCount = 16
            lineWidth = 3
            rowWidth = 5
            rowSpacing = 2
            lineSpacing = 1
            topPadding = 0
            leftPadding = 1
        case .sounds32x2rowSpacing:
            rowsCount = 4
            linesCount = 16
            lineWidth = 3
            rowWidth = 4
            rowSpacing = 4
            lineSpacing = 0
            topPadding = 3
            leftPadding = 0
        case .sounds32fillScreen:
            rowsCount = 4
            linesCount = 8
            lineWidth = 8
            rowWidth = 7
            rowSpacing = 0
            lineSpacing = 0
            topPadding = 0
            leftPadding = 0
        case .sounds64:
            rowsCount = 8
            linesCount = 8
            lineWidth = 1
            rowWidth = 1
            rowSpacing = 2
            lineSpacing = 2
            topPadding = 16
            leftPadding = 1
        case .sounds64fillScreen:
            rowsCount = 8
            linesCount = 8
            lineWidth = 8
            rowWidth = 3
            rowSpacing = 0
            lineSpacing = 0
            topPadding = 0
            leftPadding = 0
        case .sounds64x2:
            rowsCount = 8
            linesCount = 16
            lineWidth = 1
            rowWidth = 1
            rowSpacing = 2
            lineSpacing = 2
            topPadding = 5
            leftPadding = 1
        case .sounds64x2fillScreen:
            rowsCount = 8
            linesCount = 16
            lineWidth = 3
            rowWidth = 3
            rowSpacing = 0
            lineSpacing = 0
            topPadding = 4
            leftPadding = 0
        }
    }
    
    func makeMask64() -> Mask64SoundsDemo {
        var zonePresets: [SoundZone: ZoneValue] = [:]
        var prevLineY: Int?
        var counter = 0
        for line in 0..<linesCount {
            var y = line + lineWidth + (prevLineY ?? 1) + lineSpacing
            prevLineY = y - line
            if line == 0 {
                prevLineY = topPadding
                y = topPadding
            }
            var prevRowX: Int?
            var rowSounds: String = ""
            for row in 0..<rowsCount {
                var x = row + rowWidth + (prevRowX ?? 1) + rowSpacing
                prevRowX = x - row
                if row == 0 {
                    prevRowX = leftPadding
                    x = leftPadding
                }
                let soundZone = SoundZone(
                    minX: x, maxX: x + rowWidth, minY: y, maxY: y + lineWidth)
                let soundNameStr = counter >= 10 ?
                counter.description : "0\(counter)"
                let soundValue = ZoneValue(icons: nil, soundName: soundNameStr, color: .random.withAlphaComponent(0.5))
                zonePresets[soundZone] = soundValue
                counter += 1
                if counter == 32 {
                    counter = 0
                }
                rowSounds += " " + soundNameStr
            }
            print(rowSounds)
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
                color = zonePresets[$0]?.color
                return
            }
        }
        return color
    }
}
