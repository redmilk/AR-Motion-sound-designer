//
//  CaptureSessionOutputManager.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 07.12.2021.
//

import Foundation
import AVFoundation
import Combine

final class SessionOutputManager: NSObject, ErrorHandlerProvidable {
    
    var output: AnyPublisher<CMSampleBuffer, Never> { _output.eraseToAnyPublisher() }

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let audioDataOutput = AVCaptureAudioDataOutput()
    private let outputQueueForVideoAndAudio = DispatchQueue(label: "video-output-queue", qos: .userInteractive)
    private let _output = PassthroughSubject<CMSampleBuffer, Never>()

    init(captureSession: AVCaptureSession,
         sessionQueue: DispatchQueue,
         configCompletion: @escaping VoidClosure
    ) {
        super.init()
        setUpCaptureSessionOutput(captureSession: captureSession,
                                  sessionQueue: sessionQueue,
                                  configCompletion: configCompletion)
    }
    
    private func setUpCaptureSessionOutput(
        captureSession: AVCaptureSession,
        sessionQueue: DispatchQueue,
        configCompletion: @escaping VoidClosure) {
        sessionQueue.async {
            captureSession.beginConfiguration()
            // When performing latency tests to determine ideal capture settings,
            // run the app in 'release' mode to get accurate performance metrics
            do {
                try self.addOutputToCaptureSession(captureSession: captureSession)
            } catch {
                self.handleError(error)
            }
            captureSession.commitConfiguration()
        }
        configCompletion()
    }
    
    private func addOutputToCaptureSession(captureSession: AVCaptureSession) throws {
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: outputQueueForVideoAndAudio)
        guard captureSession.canAddOutput(self.videoDataOutput) else {
            throw JiggleError.videoOutputCantBeAddedToTheSession
        }
        captureSession.addOutput(videoDataOutput)
        
        guard captureSession.canAddOutput(audioDataOutput) else {
            throw JiggleError.audioOutputCantBeAddedToTheSession
        }
        audioDataOutput.setSampleBufferDelegate(self, queue: outputQueueForVideoAndAudio)
        captureSession.addOutput(audioDataOutput)
    }
}

extension SessionOutputManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        _output.send(sampleBuffer)
    }
}
