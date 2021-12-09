//
//  UtilsForPoseDetection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 09.12.2021.
//

import Foundation
import MLKit
import AVFoundation.AVCaptureDevice

struct UtilsForPoseDetection {
    
    public static func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
    ) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp
            || deviceOrientation
            == .unknown
        {
            deviceOrientation = currentUIOrientation()
        }
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            fatalError()
        }
    }
    
    /// Returns the minimum subset of all connected pose landmarks. Each key represents a start
    /// landmark, and each value in the key's value array represents an end landmark which is
    /// connected to the start landmark. These connections may be used for visualizing the landmark
    /// positions on a pose object.
    public static func poseConnections() -> [PoseLandmarkType: [PoseLandmarkType]] {
        struct PoseConnectionsHolder {
            static var connections: [PoseLandmarkType: [PoseLandmarkType]] = [
                
                PoseLandmarkType.nose: [
                    PoseLandmarkType.leftEye,
                    PoseLandmarkType.rightEye,
                    PoseLandmarkType.leftEar,
                    PoseLandmarkType.rightEar
                ],
                
                PoseLandmarkType.leftEar: [
                    PoseLandmarkType.leftEyeOuter],
                
                PoseLandmarkType.leftEyeOuter: [
                    PoseLandmarkType.leftEye],
                
                PoseLandmarkType.leftEye: [
                    PoseLandmarkType.leftEyeInner],
                
                PoseLandmarkType.leftEyeInner: [
                    PoseLandmarkType.nose],
                
                PoseLandmarkType.rightEyeInner: [
                    PoseLandmarkType.rightEye],
                
                PoseLandmarkType.rightEye: [
                    PoseLandmarkType.rightEyeOuter],
                
                PoseLandmarkType.rightEyeOuter: [
                    PoseLandmarkType.rightEar],
                
                PoseLandmarkType.mouthLeft: [
                    PoseLandmarkType.mouthRight],
                
                PoseLandmarkType.leftShoulder: [
                    PoseLandmarkType.rightShoulder,
                    PoseLandmarkType.leftHip,
                ],
                
                PoseLandmarkType.rightShoulder: [
                    PoseLandmarkType.rightHip,
                    PoseLandmarkType.rightElbow,
                ],
                
                PoseLandmarkType.rightWrist: [
                    PoseLandmarkType.rightIndexFinger,
                    PoseLandmarkType.rightPinkyFinger,
                ],
                
                PoseLandmarkType.leftHip: [
                    PoseLandmarkType.rightHip,
                    PoseLandmarkType.leftKnee],
                
                PoseLandmarkType.rightHip: [
                    PoseLandmarkType.rightKnee],
                
                PoseLandmarkType.rightKnee: [
                    PoseLandmarkType.rightAnkle],
                
                PoseLandmarkType.leftKnee: [
                    PoseLandmarkType.leftAnkle],
                
                PoseLandmarkType.leftElbow: [
                    PoseLandmarkType.leftShoulder,
                    PoseLandmarkType.leftWrist],
                
                PoseLandmarkType.rightElbow: [
                    PoseLandmarkType.rightShoulder,
                    PoseLandmarkType.rightWrist],
                
                PoseLandmarkType.leftWrist: [
                    PoseLandmarkType.leftIndexFinger,
                    PoseLandmarkType.leftPinkyFinger,
                ],
                
                PoseLandmarkType.leftAnkle: [
                    PoseLandmarkType.leftHeel,
                    PoseLandmarkType.leftToe],
                
                PoseLandmarkType.rightAnkle: [
                    PoseLandmarkType.rightHeel,
                    PoseLandmarkType.rightToe],
                
                PoseLandmarkType.rightHeel: [
                    PoseLandmarkType.rightToe],
                
                PoseLandmarkType.leftHeel: [
                    PoseLandmarkType.leftToe],
                
                PoseLandmarkType.rightIndexFinger: [
                    PoseLandmarkType.rightPinkyFinger],
                
                PoseLandmarkType.leftIndexFinger: [
                    PoseLandmarkType.leftPinkyFinger],
            ]
        }
        return PoseConnectionsHolder.connections
    }
    
    // MARK: - Private
    
    private static func currentUIOrientation() -> UIDeviceOrientation {
        let deviceOrientation = { () -> UIDeviceOrientation in
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .portrait, .unknown:
                return .portrait
            @unknown default:
                fatalError()
            }
        }
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.sync {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        return deviceOrientation()
    }
}
