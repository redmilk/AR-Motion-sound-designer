//
//  JiggleError.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 07.12.2021.
//

import Foundation

enum JiggleError: Error {
    /// capture session config
    case videoInputCantBeAddedToTheSession
    case videoOutputCantBeAddedToTheSession
    case audioOutputCantBeAddedToTheSession
    case captureDeviceInputInitialization(Error)
    case undefined(Error)
    /// pose detection
    case failedToDetectPose(Error)
    case failedToGetImageFromSampleBuffer
    
    var errorMessage: String {
        switch self {
        case .undefined(let error as NSError):
            return "Something went wrong. Error code: \(error.code). Error message: \(error.localizedDescription)"
        case .videoInputCantBeAddedToTheSession:
            return "Video input can not be added to the capture session."
        case .videoOutputCantBeAddedToTheSession:
            return "Video output can not be added to the capture session."
        case .audioOutputCantBeAddedToTheSession:
            return "Audio output can not be added to the capture session."
        case .captureDeviceInputInitialization(let error as NSError):
            return "The device cannot be opened because it is no longer available or because it is in use. Error code: \(error.code). Error message: \(error.localizedDescription)"
        case .failedToDetectPose(let error as NSError):
            return "Failed to detect pose. Error code: \(error.code). Error message: \(error.localizedDescription)"
        case .failedToGetImageFromSampleBuffer:
            return "Failed to get image buffer from sample buffer."

        }
    }
}
