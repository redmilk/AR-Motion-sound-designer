//
//  PoseDetectionService.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 09.12.2021.
//

import Foundation
import MLKit
import Combine
import AVFoundation

// MARK: - DetectionManager configuration model

final class DetectionManagerConfig {
    let capturePreviewLayer: AVCaptureVideoPreviewLayer
    let annotationOverlayView: AnnotationsOverlayView
    var shouldDrawSkeleton: Bool
    var shouldDrawCircle: Bool

    init(capturePreviewLayer: AVCaptureVideoPreviewLayer,
         annotationOverlayView: AnnotationsOverlayView,
         shouldDrawSkeleton: Bool,
         shouldDrawCircle: Bool
    ) {
        self.capturePreviewLayer = capturePreviewLayer
        self.annotationOverlayView = annotationOverlayView
        self.shouldDrawSkeleton = shouldDrawSkeleton
        self.shouldDrawCircle = shouldDrawCircle
    }
}

// MARK: - DetectionManager

final class PoseRocognizer: ErrorHandlerProvidable {
    /// API
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    /// API
    
    enum Action {
        case configure(DetectionManagerConfig)
        case buffer(CMSampleBuffer)
    }
    enum Response {
        case dotsList([CGPoint])
    }
    
    init(pointProcessor: PointProcessor = PointProcessor()) {
        self.pointProcessor = pointProcessor
        
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .configure(let configuration):
                self?.configuration = configuration
            case .buffer(let sampleBuffer):
                self?.processFrameWithSampleBuffer(sampleBuffer)
            }
        })
        .store(in: &bag)
    }
    
    /// Dependencies
    private var configuration: DetectionManagerConfig!
    
    private let pointProcessor: PointProcessor
    // For changing amount of processed or skipped frames its need to change one of this values
    private var countOfFramesForProcessing = 1
    private var countOfFramesForSkipping = 1
    private var currentProcessedFrameNumber = 0
    private var currentSkippedFrameNumber = 0
    
    /// The detector used for detecting poses. The pose detector's lifecycle is managed manually, so
    /// it is initialized on-demand via the getter override and set to `nil` when a new detector is
    /// chosen.
    private var _poseDetector: PoseDetector? = nil
    private let poseDetectorQueue = DispatchQueue(label: "com.google.mlkit.pose")
    private var poseDetector: PoseDetector? {
        get {
            var detector: PoseDetector? = nil
            poseDetectorQueue.sync {
                if _poseDetector == nil {
                    let options = PoseDetectorOptions()
                    options.detectorMode = .stream
                    //                    options.performanceMode = (currentDetector == .poseFast ? .fast : .accurate);
                    _poseDetector = PoseDetector.poseDetector(options: options)
                }
                detector = _poseDetector
            }
            return detector
        }
        set(newDetector) {
            poseDetectorQueue.sync {
                _poseDetector = newDetector
            }
        }
    }
    private var posesForPlayingSound: [PoseLandmarkType] = [
        .leftWrist,
        .rightWrist,
        .rightAnkle, .rightHeel, .rightToe, /// Left leg
        .leftAnkle, .leftHeel, .leftToe     /// Right leg
    ]
    private var bag = Set<AnyCancellable>()
}

// MARK: - Private

private extension PoseRocognizer {
    
    func processFrameWithSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        do {
            try setActiveFrameProcessing(with: sampleBuffer)
        } catch {
            handleError(error)
        }
    }
    
    func setActiveFrameProcessing(with sampleBuffer: CMSampleBuffer) throws {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw JiggleError.failedToGetImageFromSampleBuffer
        }
        
        if isNeedToSkipFrame() {
            
            let visionImage = VisionImage(buffer: sampleBuffer)
            let orientation = UtilsForPoseDetection.imageOrientation(fromDevicePosition: .front)
            
            visionImage.orientation = orientation
            let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
            let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
            try detectPose(in: visionImage, width: imageWidth, height: imageHeight)
        }
    }
    
    func detectPose(in image: VisionImage, width: CGFloat, height: CGFloat) throws {
        if let poseDetector = self.poseDetector {
            var poses: [Pose]
            do {
                poses = try poseDetector.results(in: image)
            } catch let error {
                throw JiggleError.failedToDetectPose(error)
            }
            
            guard !poses.isEmpty else { return }
            
            DispatchQueue.main.sync {
                self.removeDetectionAnnotations()
                poses.forEach { pose in
                    var dots = [CGPoint]()
                    for (_, (startLandmarkType, endLandmarkTypesArray)) in UtilsForPoseDetection.poseConnections().enumerated() {
                        let startLandmark = pose.landmark(ofType: startLandmarkType)
                        for endLandmarkType in endLandmarkTypesArray {
                            let endLandmark = pose.landmark(ofType: endLandmarkType)
                            let startLandmarkPoint = pointProcessor.normalizedPoint(
                                fromVisionPoint: startLandmark.position, videoPreviewLayer: configuration.capturePreviewLayer, width: width, height: height, type: startLandmark.type)
                            let endLandmarkPoint = pointProcessor.normalizedPoint(
                                fromVisionPoint: endLandmark.position, videoPreviewLayer: configuration.capturePreviewLayer, width: width, height: height, type: endLandmark.type)
                            
                            drawSkeletonIfNeeded(startLandmarkPoint: startLandmarkPoint, endLandmarkPoint: endLandmarkPoint)
                        }
                        
                        /// Zone Based - by dot - ??
                        posesForPlayingSound.enumerated().forEach { index, poseType in
                            if startLandmarkType.rawValue == poseType.rawValue {
                                for endLandmarkType in endLandmarkTypesArray {
                                    let landmark = pose.landmark(ofType: endLandmarkType)
                                    let filteredPoint = pointProcessor.applyOneEuroFilter(for: landmark)
                                    dots.append(pointProcessor.normalizedPoint(fromPoint: filteredPoint, videoPreviewLayer: configuration.capturePreviewLayer, width: width, height: height, type: landmark.type))
                                }
                            }
                        }
                    }
                    
                    output.send(.dotsList(dots))
                    drawLandmarksForPose(pose, width: width, height: height, shouldDrawCircle: self.configuration.shouldDrawCircle)
                }
            }
        }
    }
    
    func isNeedToSkipFrame() -> Bool {
        if currentProcessedFrameNumber == countOfFramesForProcessing {
            
            if currentSkippedFrameNumber == countOfFramesForSkipping {
                currentSkippedFrameNumber = 0
                currentProcessedFrameNumber = 0
            } else {
                currentSkippedFrameNumber += 1
            }
            return true
        } else {
            currentProcessedFrameNumber += 1
            return false
        }
    }
    
    func drawLandmarksForPose(_ pose: Pose, width: CGFloat, height: CGFloat, shouldDrawCircle: Bool) {
        for landmark in pose.landmarks {
            let filteredPoint = pointProcessor.applyOneEuroFilter(for: landmark)
            let landmarkPoint = pointProcessor.normalizedPoint(
                fromPoint: filteredPoint, videoPreviewLayer: configuration.capturePreviewLayer, width: width, height: height, type: landmark.type)
            if landmark.type == .leftAnkle ||
                landmark.type == .rightAnkle ||
                landmark.type == .leftIndexFinger ||
                landmark.type == .rightIndexFinger {
                if shouldDrawCircle {
                    UtilsForDrawing.addCircleImage(atPoint: landmarkPoint,to: self.configuration.annotationOverlayView, radius: Constant.bigDotRadius)
                }
            }
            
            if configuration.shouldDrawSkeleton {
                UtilsForDrawing.addCircle(
                    atPoint: landmarkPoint,
                    to: configuration.annotationOverlayView,
                    color: UIColor.blue,
                    radius: Constant.smallDotRadius
                )
            }
        }
    }
    
    func drawSkeletonIfNeeded(startLandmarkPoint: CGPoint, endLandmarkPoint: CGPoint) {
        if configuration.shouldDrawSkeleton {
            UtilsForDrawing.addLineSegment(
                fromPoint: startLandmarkPoint,
                toPoint: endLandmarkPoint,
                inView: configuration.annotationOverlayView,
                color: UIColor.green,
                width: Constant.lineWidth)
        }
    }
    
    func removeDetectionAnnotations() {
        for annotationView in configuration.annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
}
