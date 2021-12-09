//
//  SessionConfigurator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 08.12.2021.
//

import Foundation
import AVFoundation
import Combine

final class CaptureSessionService {
    enum Action {
        case configure(DetectionManagerConfig)
        case startSession
        case stopSession
    }
    
    enum Response {
        case configurationFinished(session: AVCaptureSession)
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "capture-session-queue", qos: .userInteractive)
    private var sessionInputManager: SessionInputManager!
    private var sessionOutputManager: SessionOutputManager!
    private var detectionManager: DetectionManager!
    private let dispatchGroup = DispatchGroup()
    private var bag = Set<AnyCancellable>()
    
    init() {
        /// service API setup
        input
            .sink(receiveValue: { [weak self] actionReceived in
                switch actionReceived {
                case .configure(let detectionConfig):
                    self?.configure(detectionConfig: detectionConfig)
                case .startSession:
                    self?.controlSession(shouldStart: true)
                case .stopSession:
                    self?.controlSession(shouldStart: false)
                }
            })
            .store(in: &self.bag)
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Private

private extension CaptureSessionService {
    func configure(detectionConfig: DetectionManagerConfig) {
        detectionManager = DetectionManager()
        detectionManager.input.send(.configure(detectionConfig))
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            self.output.send(.configurationFinished(session: self.captureSession))
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
        
        /// handle detection manager output
        detectionManager.output
            .sink(receiveValue: { [weak self] detectionResponse in
                switch detectionResponse {
                case .dotsList(let dots):
                    Logger.log("Got new dots: \(dots.count)")
                    /// play sound with dots
                }
            })
            .store(in: &self.bag)
        
        /// handle session output
        sessionOutputManager.output
            .sink(receiveValue: { [weak self] sampleBuffer in
                self?.detectionManager.input.send(.buffer(sampleBuffer))
            })
            .store(in: &self.bag)
    }
    
    func controlSession(shouldStart: Bool) {
        sessionQueue.async {
            shouldStart ? self.captureSession.startRunning() : self.captureSession.stopRunning()
        }
    }
}
