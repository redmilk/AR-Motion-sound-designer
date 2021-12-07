//
//  JiggleError.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 07.12.2021.
//

import Foundation

enum JiggleError: Error {
    case givenInputCantBeAddedToTheSession
    case captureDeviceInputInitialization(Error)
    case undefined(Error)
    
    var errorMessage: String {
        switch self {
        case .givenInputCantBeAddedToTheSession:
            return "Given input can not be added to the capture session."
        case .captureDeviceInputInitialization(let error as NSError):
            return "The device cannot be opened because it is no longer available or because it is in use. Error code: \(error.code). Error message: \(error.localizedDescription)"
        case .undefined(let error as NSError):
            return "Something went wrong. Error code: \(error.code). Error message: \(error.localizedDescription)"
        }
    }
}
