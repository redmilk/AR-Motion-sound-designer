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
import SceneKit

// MARK: - CameraViewController

final class CameraViewController: UIViewController, SessionMediaServiceProvider, PerformanceMeasurmentProvider {
    enum State {
        case captureSessionReceived(AVCaptureSession)
        case debugWindow(isHidden: Bool)
    }
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    /// debug window
    @IBOutlet weak var SceneView: SCNView!
    @IBOutlet private weak var debugWindow: DebugWindow!
    
    @IBOutlet weak var debugWindowHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var easterEgg: SCNView!
    
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
                case .debugWindow(let isHidden):
                    break
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
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /// editor updates
        EditorZoneSelection.shared.newZonePub.sink(receiveValue: { zone in
            let points = zone.keys
                .compactMap { $0.getAllPointsInsideZone() }
                .flatMap { $0 }
            let indexPathList = self.collectionView.getIndexPathsListForPoints(points)
            self.matrixCollection.input.send(.updateIndexPath(indexPathList))
        }).store(in: &bag)
        
        EditorZoneSelection.shared.interactionFeedbackPub
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] point in
                if let indexPath = self?.collectionView.indexPathForItem(at: point),
                   let cell = self?.collectionView.cellForItem(at: indexPath) as? MatrixNodeCell {
                    cell.trigger()
                }
        }).store(in: &bag)
        
        EditorZoneSelection.shared.openEditorPub
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.hideDebugWindow(false)
        }).store(in: &bag)
        
        /// debug view out
        debugWindow.output
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .scaleUpGrid: self?.matrixCollection.input.send(.scaleUp)
                case .scaleDownGrid: self?.matrixCollection.input.send(.scaleDown)
                case .shouldHideGrid(let shouldHideGrid):
                    self?.matrixCollection.input.send(.removeAll(shouldHideGrid: shouldHideGrid))
                    EditorZoneSelection.shared.requestSub.send(.resetMask)
                case .hideDebug(let isHidden):
                    self?.hideDebugWindow(isHidden)
                case .resetMask:
                    self?.matrixCollection.input.send(.removeAll(shouldHideGrid: false))
                    EditorZoneSelection.shared.requestSub.send(.resetMask)
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
        EditorZoneSelection.shared.configure(withView: collectionView, target: self)
        initializeEasterEgg()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debugWindow.configure()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// start session
        //self.viewModel.input.send(.startSession)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// stop session
        viewModel.input.send(.stopSession)
    }
    
    private func hideDebugWindow(_ isHidden: Bool) {
        debugWindowHeightConstraint.constant = isHidden ? 0 : 232
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            self.view.layoutIfNeeded()
            self.debugWindow.transform = isHidden ?
            CGAffineTransform.identity.translatedBy(x: 0.0, y: 100) : CGAffineTransform.identity
        }, completion: nil)
    }
    
    private func initializeEasterEgg() {
        scene.fogColor = UIColor.blue
        scene.fogDensityExponent = 0
        scene.set
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        lightNode.light!.color = UIColor.blue
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.blue
        scene.rootNode.addChildNode(ambientLightNode)
 
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 2, y: 1, z: 1, duration: 1)))
        
        SceneView.scene = scene
    }
}
