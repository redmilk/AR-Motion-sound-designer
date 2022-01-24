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
import MLKit

final class ZoneBasedMechanic: PoseDetectorProvider,
                               SessionMediaServiceProvider,
                               PerformanceMeasurmentProvider,
                               MaskManagerProvider {
    enum Action {
        case configure(collection: UICollectionView,
                       videoPreview: CaptureVideoPreviewView,
                       annotationsPreview: AnnotationsOverlayView)
        case startSession
        case stopSession
    }
    enum Response {
        case captureSessionReceived(AVCaptureSession)
        case playSoundForZone(_ soundName: String)
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    var isSessionRunning: Bool { sessionMediaService.isRunning }
    
    private var bag = Set<AnyCancellable>()
    private var matrixCollection: UICollectionView!
    private var configuration: DetectionManagerConfig!
    private var currentMask: MaskProtocol? { maskManager.activeMaskData }
    
    init() {
        /// handle actions input
        input.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .configure(let matrixCollection, let videoPreview, let annotationsPreview):
                    self?.matrixCollection = matrixCollection
                    let configuration = DetectionManagerConfig(
                        capturePreviewLayer: videoPreview.layer as! AVCaptureVideoPreviewLayer,
                        annotationOverlayView: annotationsPreview,
                        shouldDrawSkeleton: false,
                        shouldDrawCircle: true,
                        shouldFindAverageDot: true)
                    self?.configuration = configuration
                    self?.poseDetector.input.send(.configure(configuration))
                    self?.sessionMediaService.input.send(.configure)
                case .startSession: break
                    //self?.sessionMediaService.input.send(.startSession)
                case .stopSession:
                    self?.sessionMediaService.input.send(.stopSession)
                }
            })
            .store(in: &self.bag)
        
        /// handle detection manager output
        poseDetector.output
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] detectionResponse in
                switch detectionResponse {
                case .result(let dots, _):
                    /// play sound with dots
                    dots.forEach { point in
                        //self.drawLandmarksForPose(atPoint: point)
                        if let indexPath = self?.matrixCollection.indexPathForItem(at: point),
                           let cell = self?.matrixCollection.cellForItem(at: indexPath) as? MatrixNodeCell {
                            cell.trigger()
                            //self.output.send(.affectedNode(cell: cell, indePath: indexPath))
                            if let soundName = self?.currentMask?.determinateSoundForZonesWithIndexPath(indexPath) {
                                self?.output.send(.playSoundForZone(soundName))
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

// MARK: - Landmarks drawing

private extension ZoneBasedMechanic {
    func drawLandmarksForPose(atPoint point: CGPoint) {
        if configuration.shouldDrawCircle {
            UtilsForDrawing.addCircleImage(atPoint: point, to: self.configuration.annotationOverlayView, radius: 15)
        }
        
        if configuration.shouldDrawSkeleton {
            UtilsForDrawing.addCircle(
                atPoint: point,
                to: configuration.annotationOverlayView,
                color: UIColor.blue,
                radius: 4.0
            )
        }
    }
    
    func removeDetectionAnnotations() {
        for annotationView in configuration.annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    func drawSkeletonIfNeeded(startLandmarkPoint: CGPoint, endLandmarkPoint: CGPoint) {
        if configuration.shouldDrawSkeleton {
            //    let startLandmark = pose.landmark(ofType: startLandmarkType)
            //                    for endLandmarkType in endLandmarkTypesArray {
            //                        let endLandmark = pose.landmark(ofType: endLandmarkType)
            //                        let startLandmarkPoint = self.pointProcessor.normalizedPoint(
            //                            fromVisionPoint: startLandmark.position,
            //                            videoPreviewLayer: self.configuration.capturePreviewLayer,
            //                            shouldFindAverageDot: self.configuration.shouldFingAverageDot,
            //                            width: width,
            //                            height: height,
            //                            type: startLandmark.type)
            //                        let endLandmarkPoint = self.pointProcessor.normalizedPoint(
            //                            fromVisionPoint: endLandmark.position,
            //                            videoPreviewLayer: self.configuration.capturePreviewLayer,
            //                            shouldFindAverageDot: self.configuration.shouldFingAverageDot,
            //                            width: width,
            //                            height: height,
            //                            type: endLandmark.type)
            //                        self.drawSkeletonIfNeeded(startLandmarkPoint: startLandmarkPoint, endLandmarkPoint: endLandmarkPoint)
            //                    }
            UtilsForDrawing.addLineSegment(
                fromPoint: startLandmarkPoint,
                toPoint: endLandmarkPoint,
                inView: configuration.annotationOverlayView,
                color: UIColor.green,
                width: 3.0)
        }
    }
}
