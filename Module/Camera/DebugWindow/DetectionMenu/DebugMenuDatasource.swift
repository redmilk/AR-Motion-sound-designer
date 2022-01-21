//
//  DebugMenuSectionMaker.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import Foundation
import MLKit
import CoreVideo

// MARK: - Sound files
// MARK: - Recognizer landmarks
final class DebugMenuSectionsDatasource {
    /// sounds
    var soundsSection = DebugMenuSectionMaker.makeSoundfilesSection()
    func getSoundsSection(_ shouldRefreshList: Bool = false) -> DebugMenuSection? {
        if shouldRefreshList {
            soundsSection = DebugMenuSectionMaker.makeSoundfilesSection()
        }
        return soundsSection
    }
    /// landmarks array
    var landmarkList: [PoseLandmarkType] {
        let armsLandmarkList = landmarksSection.arms.items.filter { $0.isSelected }.map { $0.landmark }
        let legsLandmarkList = landmarksSection.legs.items.filter { $0.isSelected }.map { $0.landmark }
        let headLandmarksList = landmarksSection.head.items.filter { $0.isSelected }.map { $0.landmark }
        return [armsLandmarkList, legsLandmarkList, headLandmarksList].flatMap { $0 }
    }
    /// landmark sections carthage
    var landmarksSection = DebugMenuSectionMaker.makeLandmarksSection()
}

// MARK: - Menu section builder
fileprivate enum DebugMenuSectionMaker {
    static func makeSoundfilesSection() -> DebugMenuSection? {
        ((try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)) ?? [])
            .filter { $0.contains(".wav") || $0.contains(".mp3") }
            .map { DebugMenuItem(landmark: .nose, soundForZone: $0) }
            .sorted { $0.soundForZone ?? "" < $1.soundForZone ?? "" }
            .reduce(into: DebugMenuSection(items: [], id: ""), { partialResult, item in
                partialResult.items.append(item)
            })
    }
    static func makeLandmarksSection() -> (arms: DebugMenuSection, legs: DebugMenuSection, head: DebugMenuSection) {
        let arms: [PoseLandmarkType] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftIndexFinger, .rightIndexFinger,
            .leftPinkyFinger, .rightPinkyFinger,
            .leftThumb, .rightThumb
        ]
        let armsSection = DebugMenuSection(items: arms.map { DebugMenuItem(landmark: $0) }, id: "Arms")
        let legs: [PoseLandmarkType] = [
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
            .leftHeel, .rightHeel,
            .rightToe, .leftToe
        ]
        let legsSection = DebugMenuSection(items: legs.map { DebugMenuItem(landmark: $0) }, id: "Legs")
        let head: [PoseLandmarkType] = [
            .leftEar, .rightEar,
            .leftEye, .rightEye,
            .leftEyeInner, .rightEyeInner,
            .leftEyeOuter, .rightEyeOuter,
            .mouthLeft, .mouthRight,
            .nose
        ]
        let headSection = DebugMenuSection(items: head.map { DebugMenuItem(landmark: $0) }, id: "Head")
        return (arms: armsSection, legs: legsSection, head: headSection)
    }
}

// MARK: - Landmark types
extension PoseLandmarkType: CustomStringConvertible {
    public var description: String {
        switch self {
            /// legs
        case .leftHip: return "L hip"
        case .rightHip: return "R hip"
        case .leftKnee: return "L Knee"
        case .rightKnee: return "R Knee"
        case .leftAnkle: return "L Ankle"
        case .rightAnkle: return "R Ankle"
        case .leftHeel: return "L Heel"
        case .rightHeel: return "R Heel"
        case .rightToe: return "R Toe"
        case .leftToe: return "L Toe"
            /// arms
        case .leftShoulder: return "L Shoulder"
        case .rightShoulder: return "R Shoulder"
        case .leftElbow: return "L Elbow"
        case .rightElbow: return "R Elbow"
        case .leftWrist: return "L Wrist"
        case .rightWrist: return "R Wrist"
        case .leftIndexFinger: return "L-Index F"
        case .rightIndexFinger: return "R-Index F"
        case .leftPinkyFinger: return "L-Pinky F"
        case .rightPinkyFinger: return "R-Pinky F"
        case .rightThumb: return "R Thumb"
        case .leftThumb: return "L Thumb"
            /// head
        case .leftEar: return "L Ear"
        case .rightEar: return "R Ear"
        case .leftEye: return "L Eye"
        case .rightEye: return "R Eye"
        case .leftEyeInner: return "L-in-Eye"
        case .rightEyeInner: return "R-in-Eye"
        case .leftEyeOuter: return "L-ou-Eye"
        case .rightEyeOuter: return "R-ou-Eye"
        case .mouthLeft: return "L mouth"
        case .mouthRight: return "R mouth"
        case .nose: return "Nose"
        default:
            return "Unknown"
        }
    }
}
