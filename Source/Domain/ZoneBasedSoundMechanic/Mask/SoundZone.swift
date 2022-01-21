//
//  RobotMask.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation
import UIKit.UIImage

struct ZoneValue {
    let icons: [UIImage]?
    var soundName: String
    let color: UIColor
}

struct SoundZone: Hashable {
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
