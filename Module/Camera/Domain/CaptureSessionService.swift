//
//  SessionConfigurator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 08.12.2021.
//

import Foundation
import AVFoundation

final class CaptureSessionService {
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "capture-session-queue", qos: .userInteractive)
    
    private var sessionInputManager: SessionInputManager!
    private var sessionOutputManager: SessionOutputManager!
    private let dispatchGroup = DispatchGroup()
    
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func configure(configCompletion: @escaping (AVCaptureSession) -> Void) {
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            configCompletion(self.captureSession)
        }
        
        dispatchGroup.enter()
        sessionInputManager = SessionInputManager(
            captureSession: captureSession,
            sessionQueue: sessionQueue,
            configCompletion: { [weak self] in
                self?.dispatchGroup.leave()
            })
        
        dispatchGroup.enter()
        sessionOutputManager = SessionOutputManager(
            captureSession: captureSession,
            sessionQueue: sessionQueue,
            configCompletion: { [weak self] in
                self?.dispatchGroup.leave()
        })
    }
    
    func controlSession(shouldStart: Bool) {
        sessionQueue.async {
            shouldStart ? self.captureSession.startRunning() : self.captureSession.stopRunning()
        }
    }
}
