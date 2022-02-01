//
//  RobotMask.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation
import UIKit.UIImage

// MARK: - Zone Value
struct ZoneValue: Codable {
    enum CodingKeys: String, CodingKey { case soundName, emoji }
    
    //@CodableColor var color: UIColor
    var soundName: String
    var color: UIColor
    var emoji: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        soundName = try container.decode(String.self, forKey: .soundName)
        color = .random.withAlphaComponent(0.3)
        emoji = .emojiString
        //color = try container.decode(Color.self, forKey: .color).uiColor
    }
    init(soundName: String, emoji: String = .emojiString, color: UIColor = .random.withAlphaComponent(0.3)) {
        self.soundName = soundName
        self.color = color
        self.emoji = emoji
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(soundName, forKey: .soundName)
        try container.encode(emoji, forKey: .emoji)
        //try container.encode(Color(uiColor: color), forKey: .color)
    }
}

// MARK: - Sound Zone (Key)
struct SoundZone: Hashable, Codable {
    /// value sizes in collection nodes dimensions
    /// minX == minIndexPath.row
    /// maxY == maxIndexPath.section
    var minX: Int
    var maxX: Int
    var minY: Int
    var maxY: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(minX)
        hasher.combine(maxX)
        hasher.combine(minY)
        hasher.combine(maxY)
    }
}

/// helper methods
extension SoundZone {
    var centerPoint: CGPoint { CGPoint(x: max(1, (maxX - minX) / 2), y: max(1, (maxY - minY) / 2)) }
    var pointsAsList: [Int] { [minX, minY, maxX, maxY] }
        
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
}
