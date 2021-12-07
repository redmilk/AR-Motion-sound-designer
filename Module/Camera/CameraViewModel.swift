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
    
    /// capture session service
    private let sessionService = CaptureSessionService()

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
            case .startSession: self?.sessionService.controlSession(shouldStart: true)
            case .stopSession: self?.sessionService.controlSession(shouldStart: false)
            }
        })
        .store(in: &bag)
    }
    
    private func configureCaptureSession() {
        sessionService.configure(configCompletion: { [weak self] configuredSession in
            self?.output.send(.captureSessionReceived(configuredSession))
        })
    }
}
