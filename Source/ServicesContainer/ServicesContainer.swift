//
//  ServicesContainer.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 11.12.2021.
//

import Foundation


// MARK: - For rapid prototyping jsut add specific entity dependency to object

fileprivate let container = ServicesContainer()

final class ServicesContainer {
    lazy var poseDetector = PoseRecognizer(pointProcessor: PointProcessor())
    lazy var sessionMediaService = SessionMediaService()
    lazy var handposeMechanics = ZoneBasedMechanic()
    lazy var performanceMeasurment = PerfmormanceMeasurment()
    lazy var maskEditor = EditorZoneSelection()
    lazy var maskManager = MaskManager()
    lazy var debugDatasource = DebugMenuSectionsDatasource()
    lazy var soundDrop = SoundDropService()
}

protocol SoundDropProvidable { }
extension SoundDropProvidable {
    var soundDrop: SoundDropService { container.soundDrop }
}

/// Mask manager
protocol MaskManagerProvider { }
extension MaskManagerProvider {
    var maskManager: MaskManager { container.maskManager }
}

/// Mask editor
protocol MaskEditorProvider { }
extension MaskEditorProvider {
    var editor: EditorZoneSelection { container.maskEditor }
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
    var poseDetector: PoseRecognizer { container.poseDetector }
}

/// Debug datasources
protocol DatasourceForDebugProvider { }
extension DatasourceForDebugProvider {
    var debugDatasource: DebugMenuSectionsDatasource { container.debugDatasource }
}

// MARK: - Various application mechanics

/// Sound with Handpose Mechanics
protocol SoundWithHandposeMechanicsProvider { }
extension SoundWithHandposeMechanicsProvider {
    var handposeMechanics: ZoneBasedMechanic { container.handposeMechanics }
}


