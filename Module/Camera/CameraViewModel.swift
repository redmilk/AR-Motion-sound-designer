//
//  
//  CameraViewModel.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 06.12.2021.
//
//

import Foundation
import Combine
import AVFoundation
import UIKit

final class CameraViewModel: ErrorHandlerProvidable {
    enum Action {
        /// entry point for module
        case configureSession
        case startSession
        case stopSession
    }
    
    let input = PassthroughSubject<CameraViewModel.Action, Never>()
    let output = PassthroughSubject<CameraViewController.State, Never>()
    private let coordinator: CameraCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    
    /// capture session members
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "capture-session-queue", qos: .userInteractive)

    init(coordinator: CameraCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        handleAction()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func handleAction() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .configureSession: self?.configureCaptureSession()
            case .startSession: self?.controlSession(shouldStart: true)
            case .stopSession: self?.controlSession(shouldStart: false)
            }
        })
        .store(in: &bag)
    }
}

// MARK: - Private

private extension CameraViewModel {

    func controlSession(shouldStart: Bool) {
        sessionQueue.async {
            shouldStart ? self.captureSession.startRunning() : self.captureSession.stopRunning()
        }
    }
    
    // MARK: - Configure capture session
    
    func configureCaptureSession() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            do {
                try self.addVideoInputToCaptureSession()
            } catch {
                self.handleError(error)
            }
            self.captureSession.commitConfiguration()
        }
        self.output.send(.captureSessionReceived(self.captureSession))
    }
    
    func addVideoInputToCaptureSession() throws {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let device = discoverySession.devices.first { $0.position == .front }
        do {
            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }
            let input = try AVCaptureDeviceInput(device: device!)
            guard captureSession.canAddInput(input) else {
                throw JiggleError.givenInputCantBeAddedToTheSession
            }
            captureSession.addInput(input)
        } catch {
            throw JiggleError.captureDeviceInputInitialization(error)
        }
    }
}
