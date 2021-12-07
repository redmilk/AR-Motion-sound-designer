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
    
    @IBOutlet weak var cameraView: UIView!
        
    private let viewModel: CameraViewModel
    private var bag = Set<AnyCancellable>()

    private var videoPreviewView: CaptureVideoPreviewView!
    private var annotationOverlayView: AnnotationsOverlayView!
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: CameraViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleStates()
        viewModel.input.send(.configureSession)
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
    
    private func handleStates() {
        viewModel.output.receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] state in
            switch state {
            case .captureSessionReceived(let captureSession):
                guard let self = self else { return }
                self.videoPreviewView = CaptureVideoPreviewView(captureSession: captureSession, superView: self.view)
                self.annotationOverlayView = AnnotationsOverlayView(superView: self.view)
            }
        })
        .store(in: &bag)
    }
}
