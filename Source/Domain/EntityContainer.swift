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
    lazy var sessionMediaService = SessionMediaService()
    lazy var handposeMechanics = SoundWithHandposeMechanics()
}

/// Camera capture service media service
protocol SessionMediaServiceProvidable { }
extension SessionMediaServiceProvidable {
    var sessionMediaService: SessionMediaService { container.sessionMediaService }
}

/// Pose detector
protocol PoseDetectorProvideble { }
extension PoseDetectorProvideble {
    var poseDetector: PoseRocognizer { container.poseDetector }
}

// MARK: - Various application mechanics

/// Sound with Handpose Mechanics
protocol SoundWithHandposeMechanicsProvidable { }
extension SoundWithHandposeMechanicsProvidable {
    var handposeMechanics: SoundWithHandposeMechanics { container.handposeMechanics }
}


