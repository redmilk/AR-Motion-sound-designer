//
//  SessionConfigurator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 08.12.2021.
//

import Foundation
import AVFoundation
import Combine

/// Main concern is configuration app's basic
/// media components for camera and mic. capture session
/// Then it's ready to provide stream with audio & video buffer `CMSampleBuffer`
/// Everything related to AudioVideo data

final class SessionMediaService {
    enum Action {
        case configure
        case startSession
        case stopSession
    }
    
    enum Response {
        case configurationFinished(session: AVCaptureSession)
        case mediaBuffer(CMSampleBuffer)
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    var isRunning: Bool { captureSession.isRunning }
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "capture-session-queue", qos: .userInteractive)
    private var sessionInputManager: SessionInputManager!
    private var sessionOutputManager: SessionOutputManager!
    
    private let dispatchGroup = DispatchGroup()
    private var bag = Set<AnyCancellable>()
    
    init() {
        /// service API setup
        input
            .sink(receiveValue: { [weak self] actionReceived in
                switch actionReceived {
                case .configure:
                    self?.configure()
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

private extension SessionMediaService {
    func configure() {
        
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
        
        /// got mediaBuffer from `SessionOutputManager`
        sessionOutputManager.output
            .sink(receiveValue: { [weak self] mediaBuffer in
                self?.output.send(.mediaBuffer(mediaBuffer))
            })
            .store(in: &self.bag)
    }
    
    func controlSession(shouldStart: Bool) {
        sessionQueue.async {
            shouldStart ? self.captureSession.startRunning() : self.captureSession.stopRunning()
        }
    }
}
