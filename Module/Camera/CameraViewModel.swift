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
        case configureSession(videoPreview: CaptureVideoPreviewView, annotationsPreview: AnnotationsOverlayView)
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
        
        /// handle actions sent to self
        input
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .configureSession(let previewView, let anotationsView):
                    let detectionConfig = DetectionManagerConfig(
                        capturePreviewLayer: previewView.layer as! AVCaptureVideoPreviewLayer,
                        annotationOverlayView: anotationsView,
                        shouldDrawSkeleton: true,
                        shouldDrawCircle: true)
                    self?.sessionService.input.send(.configure(detectionConfig))
                case .startSession:
                    self?.sessionService.input.send(.startSession)
                case .stopSession:
                    self?.sessionService.input.send(.stopSession)
                }
            })
            .store(in: &bag)
        
        /// session service response
        sessionService.output
            .sink(receiveValue: { [weak self] sessionServiceResponse in
                switch sessionServiceResponse {
                case .configurationFinished(let configuredSession):
                    self?.output.send(.captureSessionReceived(configuredSession))
                }
            })
            .store(in: &bag)
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}
