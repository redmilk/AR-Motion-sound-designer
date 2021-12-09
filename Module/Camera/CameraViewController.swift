//
//  
//  CameraViewController.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 06.12.2021.
//
//

import UIKit
import Combine
import AVFoundation


// MARK: - CameraViewController

final class CameraViewController: UIViewController {
    enum State {
        case captureSessionReceived(AVCaptureSession)
    }
    
    @IBOutlet private weak var cameraView: UIView!
        
    private let viewModel: CameraViewModel
    private var bag = Set<AnyCancellable>()

    /// capture session views
    private lazy var videoPreviewView = CaptureVideoPreviewView(superView: self.cameraView)
    private lazy var annotationOverlayView = AnnotationsOverlayView(superView: self.cameraView)
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: CameraViewController.self), bundle: nil)
        
        /// handling view model's response
        viewModel.output
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] state in
                switch state {
                case .captureSessionReceived(let captureSession):
                    self?.videoPreviewView.setupWithCaptureSession(captureSession)
                }
            })
            .store(in: &bag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// entry point
        viewModel.input.send(.configureSession(videoPreview: videoPreviewView, annotationsPreview: annotationOverlayView))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// start session
        self.viewModel.input.send(.startSession)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// stop session
        viewModel.input.send(.stopSession)
    }
}

// MARK: - Private

private extension CameraViewController {
    
}
