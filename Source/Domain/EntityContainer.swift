//
//  ServicesContainer.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 11.12.2021.
//

import Foundation


// MARK: - For rapid prototyping jsut add specific entity dependency to object

fileprivate let container = EntityContainer()

final class EntityContainer {
    lazy var poseDetector = PoseRocognizer(pointProcessor: PointProcessor())
    lazy var poseDetectorNative = PoseRecognizerNative()
    lazy var sessionMediaService = SessionMediaService()
    lazy var handposeMechanics = SoundWithHandposeMechanics()
    lazy var performanceMeasurment = PerfmormanceMeasurment()
}

/// Performance measurement
protocol PerformanceMeasurmentProvider { }
extension PerformanceMeasurmentProvider {
    var performanceMeasurment: PerfmormanceMeasurment { container.performanceMeasurment }
}

/// Camera capture service media service
protocol SessionMediaServiceProvider { }
extension SessionMediaServiceProvider {
    var sessionMediaService: SessionMediaService { container.sessionMediaService }
}

/// Pose detector
protocol PoseDetectorProvider { }
extension PoseDetectorProvider {
    var poseDetector: PoseRocognizer { container.poseDetector }
}

/// Pose detector native
protocol NativePoseDetectorProvider { }
extension NativePoseDetectorProvider {
    var poseDetectorNative: PoseRecognizerNative { container.poseDetectorNative }
}

// MARK: - Various application mechanics

/// Sound with Handpose Mechanics
protocol SoundWithHandposeMechanicsProvider { }
extension SoundWithHandposeMechanicsProvider {
    var handposeMechanics: SoundWithHandposeMechanics { container.handposeMechanics }
}


