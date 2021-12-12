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

final class CameraViewController: UIViewController, SessionMediaServiceProvidable {
    enum State {
        case captureSessionReceived(AVCaptureSession)
    }
    
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!

    private lazy var matrixCollection = MatrixCollection(collectionView: collectionView)
    private let viewModel: CameraViewModel
    private var bag = Set<AnyCancellable>()

    /// capture session views
    private lazy var videoPreviewView = CaptureVideoPreviewView(superView: self.view)
    private lazy var annotationOverlayView = AnnotationsOverlayView(superView: self.view)
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: CameraViewController.self), bundle: nil)
        overrideUserInterfaceStyle = .dark
        /// handling view model's response
        viewModel.output
            //.receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .captureSessionReceived(let captureSession):
                    self.videoPreviewView.setupWithCaptureSession(captureSession)
                    /// entry point
                    
                    //self.viewModel.input.send(.startSession)
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
        self.collectionView.isHidden = true
        
        self.viewModel.input.send(.configureSession(
            videoPreview: self.videoPreviewView,
            annotationsPreview: self.annotationOverlayView,
            collectionMatrix: self.collectionView))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// start session
        self.viewModel.input.send(.startSession)
        /// entry point
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //collectionView.layer.zPosition = 1000
//        var nodes: [MatrixNode] = []
//        for _ in 0...511 {
//            let node = MatrixNode()
//            nodes.append(node)
//        }
        //matrixCollection.input.send(.configure)
        //matrixCollection.input.send(.replaceAllWithNewNodes(nodes))
       // sessionMediaService.input.send(.configure)

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
        collectionView.contentInset = UIEdgeInsets(top: 150, left: 0, bottom: 0, right:  0)
    }
}
