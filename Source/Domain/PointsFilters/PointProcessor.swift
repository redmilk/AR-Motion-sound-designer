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

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        guard rhs != 0.0 else { return lhs }
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

class MovingAverageFilter {
    var elements: [PredictedPoint?] = []
    private var limit: Int
    
    init(limit: Int) {
        guard limit > 0 else { fatalError("limit should be uppered than 0 in MovingAverageFilter init(limit:)") }
        self.elements = []
        self.limit = limit
    }
    
    func add(element: PredictedPoint?) {
        elements.append(element)
        while self.elements.count > self.limit {
            self.elements.removeFirst()
        }
    }
    
    func averagedValue() -> PredictedPoint? {
        let nonoptionalPoints: [CGPoint] = elements.compactMap{ $0?.maxPoint }
        let nonoptionalConfidences: [Float] = elements.compactMap{ $0?.maxConfidence }
        guard !nonoptionalPoints.isEmpty && !nonoptionalConfidences.isEmpty else { return nil }
        let sumPoint = nonoptionalPoints.reduce( CGPoint.zero ) { $0 + $1 }
        let sumConfidence = nonoptionalConfidences.reduce( 0.0 ) { $0 + $1 }
        return PredictedPoint(maxPoint: sumPoint / CGFloat(nonoptionalPoints.count), maxConfidence: sumConfidence)
    }
}

struct PredictedPoint {
    let maxPoint: CGPoint
    let maxConfidence: Float
    
    init(maxPoint: CGPoint, maxConfidence: Float) {
        self.maxPoint = maxPoint
        self.maxConfidence = maxConfidence
    }
    
    init(capturedPoint: CGPoint) {
        self.maxPoint = capturedPoint
        self.maxConfidence = 1
    }
}

final class PointProcessor {
    
    private var lastThreeDots: [String: [CGPoint]] = [:]
    
    /// One Euro Filter
    var oneEuroFiltersForBodyParts: [PoseLandmarkType: (x: OneEuroFilter, y: OneEuroFilter)] = [:]
    var initialTime: Double?
    
    var mvfilters: [MovingAverageFilter] = []
    
    /// to try in pose detector
    ///         let mvaPoints = self.pointProcessor.mvaFilter(predictedPoints: dots.map { PredictedPoint(maxPoint: $0.0, maxConfidence: $0.1) })
    func mvaFilter(predictedPoints: [PredictedPoint]) -> [PredictedPoint?] {
        if predictedPoints.count != mvfilters.count {
            mvfilters = predictedPoints.map { _ in MovingAverageFilter(limit: 3) }
        }
        for (predictedPoint, filter) in zip(predictedPoints, mvfilters) {
            filter.add(element: predictedPoint)
        }
        return mvfilters.map { $0.averagedValue() }
    }
    
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
