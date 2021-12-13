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
    var shouldFingAverageDot: Bool

    init(capturePreviewLayer: AVCaptureVideoPreviewLayer,
         annotationOverlayView: AnnotationsOverlayView,
         shouldDrawSkeleton: Bool,
         shouldDrawCircle: Bool,
         shouldFindAverageDot: Bool
    ) {
        self.capturePreviewLayer = capturePreviewLayer
        self.annotationOverlayView = annotationOverlayView
        self.shouldDrawSkeleton = shouldDrawSkeleton
        self.shouldDrawCircle = shouldDrawCircle
        self.shouldFingAverageDot = shouldFindAverageDot
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
 
    private let poseDetectorQueue = DispatchQueue(label: "com.google.mlkit.pose", qos: .userInteractive)
    private lazy var poseDetector: PoseDetector = {
        let options = PoseDetectorOptions()
        options.detectorMode = .stream
        return PoseDetector.poseDetector(options: options)
    }()

    private var posesForPlayingSound: [PoseLandmarkType] = [
        .leftWrist,
        .rightWrist,
        //.leftEye, .rightEye, .leftEar, .rightEar, .mouthLeft, .mouthRight, .leftEyeOuter, .rightEyeOuter, .leftEyeInner, .rightEyeInner, .nose
        //.rightAnkle, .rightHeel, .rightToe, /// Left leg
        //.leftAnkle, .leftHeel, .leftToe     /// Right leg
    ]
    private var bag = Set<AnyCancellable>()
}

// MARK: - Private

private extension PoseRocognizer {
    
    func processFrameWithSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        do {
            try setActiveFrameProcessing(with: sampleBuffer, shouldSkipFrame: false)
        } catch {
            handleError(error)
        }
    }
    
    func setActiveFrameProcessing(with sampleBuffer: CMSampleBuffer, shouldSkipFrame: Bool) throws {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw JiggleError.failedToGetImageFromSampleBuffer
        }
        
        if !shouldSkipFrame {
            let visionImage = VisionImage(buffer: sampleBuffer)
            let orientation = UtilsForPoseDetection.imageOrientation(fromDevicePosition: .front)
            
            visionImage.orientation = orientation
            let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
            let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
            try detectPose(in: visionImage, width: imageWidth, height: imageHeight)
        }
    }
    
    func detectPose(in image: VisionImage, width: CGFloat, height: CGFloat) throws {
        poseDetectorQueue.async {
            guard let pose = try? self.poseDetector.results(in: image).first else { return }
          
            DispatchQueue.main.async {
                self.removeDetectionAnnotations()
                var dots = [CGPoint]()
                for (_, (startLandmarkType, endLandmarkTypesArray)) in UtilsForPoseDetection.poseConnections().enumerated() {
                    /// draw skeleton was here
                    
                    /// Zone Based - by dot - ??
                    self.posesForPlayingSound.forEach { poseType in
                        if startLandmarkType.rawValue == poseType.rawValue {
                            for endLandmarkType in endLandmarkTypesArray {
                                let landmark = pose.landmark(ofType: endLandmarkType)
                                let filteredPoint = self.pointProcessor.applyOneEuroFilter(for: landmark)
                                let normalizedPoint = self.pointProcessor.normalizedPoint(
                                    fromPoint: filteredPoint,
                                    videoPreviewLayer: self.configuration.capturePreviewLayer,
                                    shouldFindAverageDot: self.configuration.shouldFingAverageDot,
                                    width: width,
                                    height: height,
                                    type: landmark.type)
                                dots.append(normalizedPoint)
                            }
                        }
                    }
                }
                self.drawLandmarksForPose(pose, width: width, height: height, shouldDrawCircle: self.configuration.shouldDrawCircle)
                self.output.send(.dotsList(dots))
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
                fromPoint: filteredPoint,
                videoPreviewLayer: configuration.capturePreviewLayer,
                shouldFindAverageDot: configuration.shouldFingAverageDot,
                width: width,
                height: height,
                type: landmark.type)
            if landmark.type == .leftWrist ||
                landmark.type == .leftPinkyFinger ||
                landmark.type == .leftIndexFinger ||
                landmark.type == .rightPinkyFinger ||
                landmark.type == .rightIndexFinger ||
                landmark.type == .rightWrist { /// landmark.type == .leftAnkle || landmark.type == .rightAnkle || was here
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
                width: Constant.lineWidth)
        }
    }
    
    func removeDetectionAnnotations() {
        for annotationView in configuration.annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
}
