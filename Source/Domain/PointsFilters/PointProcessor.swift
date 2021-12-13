//
//  PointUtils.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 09.12.2021.
//

import Foundation
import MLKit
import QuartzCore
import AVFoundation.AVCaptureVideoPreviewLayer

final class PointProcessor {
    
    private var lastThreeDots: [String: [CGPoint]] = [:]
    
    /// One Euro Filter
    var oneEuroFiltersForBodyParts: [PoseLandmarkType: (x: OneEuroFilter, y: OneEuroFilter)] = [:]
    var initialTime: Double?
    
    func normalizedPoint(
        fromVisionPoint point: VisionPoint,
        videoPreviewLayer: AVCaptureVideoPreviewLayer,
        shouldFindAverageDot: Bool,
        width: CGFloat,
        height: CGFloat,
        type: PoseLandmarkType
    ) -> CGPoint {
        let cgPoint = CGPoint(x: point.x, y: point.y)
        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalizedPoint = videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        
        if shouldFindAverageDot {
            return averageDot(newDot: normalizedPoint, type: type)
        }
        
        return normalizedPoint
    }
    
    func normalizedPoint(
        fromPoint cgPoint: CGPoint,
        videoPreviewLayer: AVCaptureVideoPreviewLayer,
        shouldFindAverageDot: Bool,
        width: CGFloat,
        height: CGFloat,
        type: PoseLandmarkType
    ) -> CGPoint {
        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalizedPoint = videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        
        if shouldFindAverageDot {
            return averageDot(newDot: normalizedPoint, type: type)
        }
        
        return normalizedPoint
    }
    
    func averageDot(newDot: CGPoint, type: PoseLandmarkType) -> CGPoint {
        let numberOfLastDots = Constant.lastDotsNumber
        
        var lastThreeDotsOfType = lastThreeDots[type.rawValue]
        if lastThreeDotsOfType == nil {
            lastThreeDotsOfType = [CGPoint](repeating: CGPoint(x:0, y:0), count: numberOfLastDots)
        }

        for i in stride(from: numberOfLastDots-1, to: 0, by: -1) {
            if let prev = lastThreeDotsOfType?[i-1] {
                lastThreeDotsOfType?[i] = prev
            }
        }
        lastThreeDotsOfType?[0] = newDot
        lastThreeDots[type.rawValue] = lastThreeDotsOfType

        var sumX = 0.0, sumY = 0.0, countX = 0, countY = 0
        
        if let lastThreeDotsOfType = lastThreeDotsOfType {
            for i in 0..<numberOfLastDots {
                
                let dot = lastThreeDotsOfType[i]
                        
                sumX += Double(dot.x)
                sumY += Double(dot.y)
                
                if dot.x != CGFloat(0.0) {
                    countX += 1
                }
                if dot.y != CGFloat(0.0) {
                    countY += 1
                }
            }
        }
        
        return CGPoint(x: sumX/Double(countX), y: sumY/Double(countY))
    }
    
    func applyOneEuroFilter(for pose: PoseLandmark) -> CGPoint {
        
        var point = CGPoint(x: pose.position.x, y: pose.position.y)
        
        if oneEuroFiltersForBodyParts.keys.contains(pose.type) {
            let filtersTuple = oneEuroFiltersForBodyParts[pose.type]
            if let initialTime = initialTime {
                let timestamp = NSDate.timeIntervalSinceReferenceDate - initialTime
                if let xFilter = filtersTuple?.x {
                    point.x = CGFloat(xFilter.filter(t: Float(timestamp), x: Float(pose.position.x)))
                }
                if let yFilter = filtersTuple?.y {
                    point.y = CGFloat(yFilter.filter(t: Float(timestamp), x: Float(pose.position.y)))
                }
            }
        } else {
            initialTime = NSDate.timeIntervalSinceReferenceDate
            let timestamp = NSDate.timeIntervalSinceReferenceDate - initialTime!
            oneEuroFiltersForBodyParts[pose.type] = (x: OneEuroFilter(t0: Float(timestamp), x0: Float(pose.position.x)), y: OneEuroFilter(t0: Float(timestamp), x0: Float(pose.position.y)))
        }
        
        return point
    }

}
