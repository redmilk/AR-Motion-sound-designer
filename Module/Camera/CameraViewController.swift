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
    
    @IBOutlet weak var scaleUpGridButton: UIBarButtonItem!
    @IBOutlet weak var currentGridScaleLabel: UIBarButtonItem!
    @IBOutlet weak var scaleDownGridButton: UIBarButtonItem!
    
    @IBOutlet weak var fpsButton: UIBarButtonItem!
    @IBOutlet weak var debugStackView: UIStackView!
    @IBOutlet weak var detectionTimeLabel: UILabel!
    @IBOutlet weak var executionTimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
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
        
        performanceMeasurment.output.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .measurement(let fps):
                    self?.fpsLabel.text = fps
                case _: break
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

        configureView()
        
        viewModel.input.send(
            .configureSession(
                videoPreview: videoPreviewView,
                annotationsPreview: annotationOverlayView,
                collectionMatrix: collectionView
            )
        )
        
        performanceMeasurment.input.send(.startMeasure)
        matrixCollection.input.send(.initialSetup)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// start session
        self.viewModel.input.send(.startSession)
        matrixCollection.input.send(.configureScaling(.scale128))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// stop session
        viewModel.input.send(.stopSession)
    }
}

// MARK: - Private

private extension CameraViewController {
    func configureView() {
        scaleUpGridButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.matrixCollection.input.send(.scaleUp)
            })
            .store(in: &bag)
        
        scaleDownGridButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.matrixCollection.input.send(.scaleDown)
            })
            .store(in: &bag)
        
        matrixCollection.output
            .sink(receiveValue: { [weak self] matrixResponse in
                switch matrixResponse {
                case .currentScale(let scale):
                    self?.updateScalefactorLabel(scale)
                case _: break
                }
            })
            .store(in: &bag)
        
        fpsButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.debugStackView.isHidden.toggle()
            })
            .store(in: &bag)
    }
    
    func updateScalefactorLabel(_ scale: MatrixCollection.GridScale) {
        switch scale {
        case .scale2048: currentGridScaleLabel.title = "2048"
        case .scale1024: currentGridScaleLabel.title = "1024"
        case .scale512: currentGridScaleLabel.title = "512"
        case .scale256: currentGridScaleLabel.title = "256"
        case .scale128: currentGridScaleLabel.title = "128"
        }
    }
}
