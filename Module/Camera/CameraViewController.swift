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

final class CameraViewController: UIViewController, SessionMediaServiceProvider, PerformanceMeasurmentProvider {
    enum State {
        case captureSessionReceived(AVCaptureSession)
    }
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    /// debug window
    @IBOutlet private weak var debugWindow: DebugWindow!

    private lazy var matrixCollection = MatrixCollection(collectionView: collectionView)
    private let viewModel: CameraViewModel
    private var bag = Set<AnyCancellable>()
    
    /// capture session views
    private lazy var videoPreviewView = CaptureVideoPreviewView(superView: self.containerView)
    private lazy var annotationOverlayView = AnnotationsOverlayView(superView: self.containerView)
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: CameraViewController.self), bundle: nil)
        overrideUserInterfaceStyle = .dark

        /// handling view model's response
        viewModel.output
            .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .captureSessionReceived(let captureSession):
                    self.videoPreviewView.setupWithCaptureSession(captureSession)
                    self.viewModel.input.send(.startSession)
                    self.containerView.bringSubviewToFront(self.collectionView)
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

        /// debug view out
        debugWindow.output
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .scaleUpGrid: self?.matrixCollection.input.send(.scaleUp)
                case .scaleDownGrid: self?.matrixCollection.input.send(.scaleDown)
                case .shouldHideGrid(let shouldHideGrid):
                    self?.matrixCollection.input.send(.shouldHideGrid(shouldHideGrid))
                }
            })
            .store(in: &bag)
        
        matrixCollection.output
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .didPressNode(_): break
                case .currentScale(let currentScale):
                    self?.debugWindow.input.send(.currentScale(currentScale))
                }
            })
            .store(in: &bag)

        viewModel.input.send(.configureSession(
            videoPreview: videoPreviewView,
            annotationsPreview: annotationOverlayView,
            collectionMatrix: collectionView))
        
        performanceMeasurment.input.send(.startMeasure)
        matrixCollection.input.send(.initialSetup)
        matrixCollection.input.send(.configureScaling(scale: .scale2048, isGridHidden: false))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        debugWindow.configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// start session
        self.viewModel.input.send(.startSession)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// stop session
        viewModel.input.send(.stopSession)
    }
}
