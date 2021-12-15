//
//  PoseRecognizerNative.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 14.12.2021.
//

import Foundation
import Vision
import UIKit
import Combine

final class PoseRecognizerNative {
    enum Action {
        case configure(DetectionManagerConfig)
        case buffer(CMSampleBuffer)
    }
    enum Response {
        case dotsList([CGPoint])
    }
    
    /// API
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    /// API
   
    private var bag = Set<AnyCancellable>()
    private var configuration: DetectionManagerConfig!
    
    var imageWidth: CGFloat!
    var imageHeight: CGFloat!

    
    init() {
        input
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .configure(let configuration):
                    self?.configuration = configuration
                case .buffer(let sampleBuffer):
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                    self?.imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
                    self?.imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))

                    let ciimage = CIImage(cvPixelBuffer: imageBuffer)
                    let context = CIContext(options: nil)
                    let cgImage = context.createCGImage(ciimage, from: ciimage.extent)!
                    self?.processImage(bufferImage: cgImage)
                }
            })
            .store(in: &bag)
    }
        
    func processImage(bufferImage: CGImage) {
        let requestHandler = VNImageRequestHandler(cgImage: bufferImage)

        // Create a new request to recognize a human body pose.
        let request = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)

        do {
            // Perform the body pose-detection request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }
    
    func bodyPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation] else {
            return
        }
        
        // Process each observation to find the recognized body pose points.
        observations.forEach { processObservation($0) }
    }
    
    func processObservation(_ observation: VNHumanBodyPoseObservation) {
        
        // Retrieve all torso points.
        guard let recognizedPoints = try? observation.recognizedPoints(.torso) else { return }
        
        // Torso joint names in a clockwise ordering.
        let torsoJointNames: [VNHumanBodyPoseObservation.JointName] = [
//            .neck,
//            .rightShoulder,
//            .rightHip,
//            .root,
//            .leftHip,
//            .leftShoulder,
            .rightWrist,
            .leftWrist
        ]
        
        // Retrieve the CGPoints containing the normalized X and Y coordinates.
        let imagePoints: [CGPoint] = torsoJointNames.compactMap {
            guard let point = recognizedPoints[$0], point.confidence > 0.2 else { return nil }
            // Translate the point from normalized-coordinates to image coordinates.
            return VNImagePointForNormalizedPoint(point.location,
                                                  Int(imageWidth),
                                                  Int(imageHeight))
        }

        output.send(.dotsList(imagePoints))
        // Draw the points onscreen.
        //draw(points: imagePoints)
    }
    
}
