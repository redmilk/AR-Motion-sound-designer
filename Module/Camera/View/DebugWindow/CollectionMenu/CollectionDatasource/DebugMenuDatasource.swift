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
        case .leftHip: return "left hip"
        case .rightHip: return "right hip"
        case .leftKnee: return "left Knee"
        case .rightKnee: return "right Knee"
        case .leftAnkle: return "left Ankle"
        case .rightAnkle: return "right Ankle"
        case .leftHeel: return "left Heel"
        case .rightHeel: return "right Heel"
        case .rightToe: return "right Toe"
        case .leftToe: return "left Toe"
            /// arms
        case .leftShoulder: return "left Shoulder"
        case .rightShoulder: return "right Shoulder"
        case .leftElbow: return "left Elbow"
        case .rightElbow: return "right Elbow"
        case .leftWrist: return "left Wrist"
        case .rightWrist: return "right Wrist"
        case .leftIndexFinger: return "left Index Finger"
        case .rightIndexFinger: return "right Index Finger"
        case .leftPinkyFinger: return "left Pinky Finger"
        case .rightPinkyFinger: return "right Pinky Finger"
        case .rightThumb: return "right Thumb"
        case .leftThumb: return "left Thumb"
            /// head
        case .leftEar: return "left Ear"
        case .rightEar: return "right Ear"
        case .leftEye: return "left Eye"
        case .rightEye: return "right Eye"
        case .leftEyeInner: return "left Eye Inner"
        case .rightEyeInner: return "right Eye Inner"
        case .leftEyeOuter: return "left Eye Outer"
        case .rightEyeOuter: return "right Eye Outer"
        case .mouthLeft: return "mouth Left"
        case .mouthRight: return "mouth Right"
        case .nose: return "Nose"
        default:
            return "Unknown"
        }
    }
}
