//
//  Mask64Mapper.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 23.12.2021.
//

import Foundation
import UIKit.UIColor

final class MaskAutoMapper {
    private var rowsCount: Int!
    private var linesCount: Int!
    private var lineWidth: Int!
    private var rowWidth: Int!
    private var rowSpacing: Int!
    private var lineSpacing: Int!
    private var topPadding: Int!
    private var leftPadding: Int!
    private var soundFilesTotal: Int!
    private var soundsPrefixList: [String]
    private var template: Template!
    
    init(template: Template, soundsPrefixList: [String]) {
        self.template = template
        self.soundsPrefixList = soundsPrefixList
    }
    
    func makeMask(with soundPrefix: String) -> MaskBase {
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
                let soundNameStr = counter >= 10 ? "\(soundPrefix)\(counter)" : "\(soundPrefix)0\(counter)"
                let soundValue = ZoneValue(soundName: soundNameStr, color: .random.withAlphaComponent(0.1))
                zonePresets[soundZone] = soundValue
                counter += 1
                if counter == soundFilesTotal {
                    counter = 0
                }
                rowSounds += " " + soundNameStr
            }
            //print(rowSounds)
            prevRowX = nil
        }
        return MaskBase(zonePresets: zonePresets, createdWith: self.template.rawValue)
    }
}

extension MaskAutoMapper {
    enum Template: String, CaseIterable, Codable {
        case unknown
        case editor
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
        
    func generateAllTemplates() -> [MaskBase] {
        var result: [MaskBase] = []
        Template.allCases.forEach { templateType in
            switch templateType {
            case .editor, .unknown: break
            case .sounds32equal:
                rowsCount = 4
                linesCount = 8
                lineWidth = 4   // MARK: -  You feel this smells, I know ;-) Refactor soon
                rowWidth = 3
                rowSpacing = 4
                lineSpacing = 4
                topPadding = 2
                leftPadding = 2
                soundFilesTotal = 32
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds32:
                rowsCount = 4
                linesCount = 8
                lineWidth = 5
                rowWidth = 4
                rowSpacing = 4
                lineSpacing = 3
                topPadding = 2
                leftPadding = 0
                soundFilesTotal = 32
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds32x2:
                rowsCount = 4
                linesCount = 16
                lineWidth = 3
                rowWidth = 5
                rowSpacing = 2
                lineSpacing = 1
                topPadding = 0
                leftPadding = 1
                soundFilesTotal = 32
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds32x2rowSpacing:
                rowsCount = 4
                linesCount = 16
                lineWidth = 3
                rowWidth = 4
                rowSpacing = 4
                lineSpacing = 0
                topPadding = 3
                leftPadding = 0
                soundFilesTotal = 32
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds32fillScreen:
                rowsCount = 4
                linesCount = 8
                lineWidth = 8
                rowWidth = 7
                rowSpacing = 0
                lineSpacing = 0
                topPadding = 0
                leftPadding = 0
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
                soundFilesTotal = 32
            case .sounds64:
                rowsCount = 8
                linesCount = 8
                lineWidth = 1
                rowWidth = 1
                rowSpacing = 2
                lineSpacing = 2
                topPadding = 16
                leftPadding = 1
                soundFilesTotal = 64
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds64fillScreen:
                rowsCount = 8
                linesCount = 8
                lineWidth = 8
                rowWidth = 3
                rowSpacing = 0
                lineSpacing = 0
                topPadding = 0
                leftPadding = 0
                soundFilesTotal = 64
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds64x2:
                rowsCount = 8
                linesCount = 16
                lineWidth = 1
                rowWidth = 1
                rowSpacing = 2
                lineSpacing = 2
                topPadding = 5
                leftPadding = 1
                soundFilesTotal = 64
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            case .sounds64x2fillScreen:
                rowsCount = 8
                linesCount = 16
                lineWidth = 3
                rowWidth = 3
                rowSpacing = 0
                lineSpacing = 0
                topPadding = 4
                leftPadding = 0
                soundFilesTotal = 64
                template = templateType
                soundsPrefixList.forEach { result.append(self.makeMask(with: $0)) }
            }
        }
        return result
    }
}
