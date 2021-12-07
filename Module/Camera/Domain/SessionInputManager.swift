//
//  SessionInputManager.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 07.12.2021.
//

import Foundation
import AVFoundation

final class SessionInputManager: NSObject, ErrorHandlerProvidable {
        
    init(captureSession: AVCaptureSession,
         sessionQueue: DispatchQueue,
         configCompletion: @escaping VoidClosure
    ) {
        super.init()
        configureCaptureSession(captureSession: captureSession, sessionQueue: sessionQueue, configCompletion: configCompletion)
    }
        
    private func configureCaptureSession(
        captureSession: AVCaptureSession,
        sessionQueue: DispatchQueue,
        configCompletion: @escaping VoidClosure
    ) {
        sessionQueue.async {
            captureSession.beginConfiguration()
            do {
                try self.addVideoInputToCaptureSession(captureSession: captureSession)
            } catch {
                self.handleError(error)
            }
            captureSession.commitConfiguration()
        }
        configCompletion()
    }
    
    private func addVideoInputToCaptureSession(captureSession: AVCaptureSession) throws {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let device = discoverySession.devices.first { $0.position == .front }
        do {
            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }
            let input = try AVCaptureDeviceInput(device: device!)
            guard captureSession.canAddInput(input) else {
                throw JiggleError.videoInputCantBeAddedToTheSession
            }
            captureSession.addInput(input)
        } catch {
            throw JiggleError.captureDeviceInputInitialization(error)
        }
    }
}
