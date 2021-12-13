//
//  TriggerSoundWithHandPose.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 11.12.2021.
//

import Combine
import Foundation
import UIKit
import AVFoundation.AVCaptureVideoPreviewLayer

final class SoundWithHandposeMechanics: PoseDetectorProvideble, SessionMediaServiceProvidable {
    enum Action {
        
        case configure(collection: UICollectionView,
                       videoPreview: CaptureVideoPreviewView,
                       annotationsPreview: AnnotationsOverlayView)
        case startSession
        case stopSession
    }
    enum Response {
        case captureSessionReceived(AVCaptureSession)
        case affectedNode(cell: MatrixNodeCell, indePath: IndexPath)
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    private var bag = Set<AnyCancellable>()
    private var matrixCollection: UICollectionView!
    
    init() {
        /// handle actions input
        input
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .configure(let matrixCollection, let videoPreview, let annotationsPreview):
                    self?.matrixCollection = matrixCollection
                    let detectionConfig = DetectionManagerConfig(
                        capturePreviewLayer: videoPreview.layer as! AVCaptureVideoPreviewLayer,
                        annotationOverlayView: annotationsPreview,
                        shouldDrawSkeleton: false,
                        shouldDrawCircle: true)
                    self?.poseDetector.input.send(.configure(detectionConfig))
                    self?.sessionMediaService.input.send(.configure)
                case .startSession:
                    self?.sessionMediaService.input.send(.startSession)
                case .stopSession:
                    self?.sessionMediaService.input.send(.stopSession)
                }
            })
            .store(in: &self.bag)
        
        /// handle detection manager output
        poseDetector.output.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] detectionResponse in
                guard let self = self else { return }
                switch detectionResponse {
                case .dotsList(let dots):
                    /// play sound with dots
                    dots.forEach { point in
                        if let indexPath = self.matrixCollection.indexPathForItem(at: point),
                           let cell = self.matrixCollection.cellForItem(at: indexPath) as? MatrixNodeCell {
                            self.output.send(.affectedNode(cell: cell, indePath: indexPath))

                            let zoneHitTest = ZoneTriggerHitTest(zone: cell.bounds, dot: point)
                            if zoneHitTest.validateConditions() {
                                
                              //  self.output.send(.affectedNode(cell: cell, indePath: indexPath))
                            }
                        }
                    }
                }
            })
            .store(in: &self.bag)
        
        /// handle session output
        sessionMediaService.output
            .sink(receiveValue: { [weak self] sessionMediaResponse in
                guard let self = self else { return }
                switch sessionMediaResponse {
                case .mediaBuffer(let sampleBuffer):
                    self.poseDetector.input.send(.buffer(sampleBuffer))
                case .configurationFinished(let preconfiguredCaptureSession):
                    self.output.send(.captureSessionReceived(preconfiguredCaptureSession))
                }
            })
            .store(in: &self.bag)
    }
    
}
