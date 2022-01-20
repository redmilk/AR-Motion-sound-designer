//
//  DebugMenuSectionMaker.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import Foundation
import MLKit

let menuData = DebugMenuSectionsDatasource()

final class DebugMenuSectionsDatasource {
    var arms = DebugMenuSectionMaker.arms.section
    var legs = DebugMenuSectionMaker.legs.section
    var head = DebugMenuSectionMaker.head.section
    
    var currentTrackingLandmarks: [PoseLandmarkType] {
        let armsLandmarkList = arms.items.filter { $0.isSelected }.map { $0.landmark }
        let legsLandmarkList = legs.items.filter { $0.isSelected }.map { $0.landmark }
        let headLandmarksList = head.items.filter { $0.isSelected }.map { $0.landmark }
        return [armsLandmarkList, legsLandmarkList, headLandmarksList].flatMap { $0 }
    }
}

fileprivate enum DebugMenuSectionMaker {
    case arms
    case legs
    case head
    var section: DebugMenuSection {
        switch self {
        case .arms:
            let items: [PoseLandmarkType] = [
                .leftShoulder, .rightShoulder,
                .leftElbow, .rightElbow,
                .leftWrist, .rightWrist,
                .leftIndexFinger, .rightIndexFinger,
                .leftPinkyFinger, .rightPinkyFinger,
                .leftThumb, .rightThumb
            ]
            return DebugMenuSection(items: items.map { DebugMenuItem(landmark: $0) }, id: "Arms")
        case .legs:
            let items: [PoseLandmarkType] = [
                .leftHip, .rightHip,
                .leftKnee, .rightKnee,
                .leftAnkle, .rightAnkle,
                .leftHeel, .rightHeel,
                .rightToe, .leftToe
            ]
            return DebugMenuSection(items: items.map { DebugMenuItem(landmark: $0) }, id: "Legs")
        case .head:
            let items: [PoseLandmarkType] = [
                .leftEar, .rightEar,
                .leftEye, .rightEye,
                .leftEyeInner, .rightEyeInner,
                .leftEyeOuter, .rightEyeOuter,
                .mouthLeft, .mouthRight,
                .nose
            ]
            return DebugMenuSection(items: items.map { DebugMenuItem(landmark: $0) }, id: "Head")
        }
    }
}

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
