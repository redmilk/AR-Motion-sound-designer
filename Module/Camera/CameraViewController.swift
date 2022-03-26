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

final class CameraViewController: UIViewController,
                                    SessionMediaServiceProvider,
                                    PerformanceMeasurmentProvider,
                                    AlertPresentable,
                                    MaskManagerProvider,
                                    MaskEditorProvider {
    enum State {
        case captureSessionReceived(AVCaptureSession)
        case debugWindow(isHidden: Bool)
    }
    
    @IBOutlet private weak var recognizersContainer: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    /// debug window
    @IBOutlet private weak var debugWindow: DebugWindow!    
    @IBOutlet weak var debugWindowBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var debugWindowTopConstraint: NSLayoutConstraint!
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
                    //self.viewModel.input.send(.startSession)
                    self.containerView.bringSubviewToFront(self.collectionView)
                case .debugWindow(_): break
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
        /// mask manager updates
        maskManager.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .importedMask(let mask):
                self?.matrixCollection.input.send(.drawMask(mask.zonePresets))
            case .nextMask(let mask, let descriptionModel):
                self?.matrixCollection.input.send(.drawMask(mask.zonePresets))
                self?.editor.input.send(.setupMask(mask))
                self?.debugWindow.input.send(.displaySelectedMaskDescriptionsModel(descriptionModel))
            }
        }).store(in: &bag)
        editor.newZonePub
            .sink(receiveValue: { [weak self] zone in
                self?.matrixCollection.input.send(.drawZone(zone))
            }).store(in: &bag)
        editor.interactionFeedbackPub
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] point in
                if let indexPath = self?.collectionView.indexPathForItem(at: point),
                   let cell = self?.collectionView.cellForItem(at: indexPath) as? MatrixNodeCell {
                    cell.trigger()
                }
        }).store(in: &bag)
        editor.openEditorPub
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.hideDebugWindow(false)
                //self?.debugWindow.input.send(.forcedMode(.idle))
        }).store(in: &bag)
        editor.modeSwitchPub
            .sink(receiveValue: { [weak self] mode in
                self?.debugWindow.input.send(.forcedMode(mode))
        }).store(in: &bag)
        editor.selectedZoneRectPub
            .sink(receiveValue: { [weak self] zoneRect in
                self?.recognizersContainer.drawRect(zoneRect)
        }).store(in: &bag)
        editor.deleteZonePub
            .sink(receiveValue: { [weak self] zone in
                self?.matrixCollection.input.send(.deleteZone(zone))
        }).store(in: &bag)
        editor.currentSelectedZoneInfoPub
            .sink(receiveValue: { [weak self] editorInfo in
                self?.debugWindow.input.send(.currentZoneInfo(editorInfo))
        }).store(in: &bag)
        
        /// debug view out
        debugWindow.output.sink(receiveValue: { [weak self] response in
                switch response {
                case .shouldHideGrid(let shouldHideGrid):
                    self?.matrixCollection.input.send(.removeAll(shouldHideGrid: shouldHideGrid))
                    self?.editor.input.send(.resetMask)
                case .resetMask:
                    guard let self = self else { return }
                    self.displayAlert(fromParentView: self.view, with: "All your progress will be lost. Are you sure you want to discard current changes?", title: "Confirm to reset", isDangerAction: true, action: {
                    }, buttonTitle: "Cancel", extraAction: { [weak self] in
                        self?.matrixCollection.input.send(.removeAll(shouldHideGrid: false))
                        self?.editor.input.send(.resetMask)
                    }, extraActionTitle: "DISCARD CHANGES")
                case .editorMode(let mode):
                    self?.editor.input.send(.mode(mode))
                case .transformZone(let x, let y, let w, let h):
                    self?.editor.input.send(.transformZone(x: x, y: y, w: w, h: h))
                case .soundForZone(let soundName):
                    self?.editor.input.send(.soundForCurrentZone(soundName))
                case .maskSaveAndExport:
                    guard let mask = self?.editor.mask, let maskJSON = self?.maskManager.exportJSON(with: mask) else { return }
                    self?.share(with: maskJSON)
                    self?.maskManager.saveMask(with: maskJSON)
                case .maskImportFromPasteboard:
                    self?.maskManager.importFromClipboard()
                case .toggleCamera:
                    self?.viewModel.input.send(.toggleSession)
                case .hideDebug(let isHidden):
                    self?.hideDebugWindow(isHidden)
                case .toggleFlipMenu:
                    self?.toggleMenuTopBottom()
                    self?.debugWindow.input.send(.toggleFlipMenu)
                case .undoAction:
                    self?.editor.input.send(.undo)
                case .nextTemplate:
                    self?.maskManager.input.send(.getNextMask)
                case .prevTemplate:
                    self?.maskManager.input.send(.getNextMask)
                }
            }).store(in: &bag)

        viewModel.input.send(.configureSession(
            videoPreview: videoPreviewView,
            annotationsPreview: annotationOverlayView,
            collectionMatrix: collectionView))
        
        performanceMeasurment.input.send(.startMeasure)
        matrixCollection.input.send(.initialSetup(isGridHidden: false))
        editor.configure(withView: recognizersContainer, gridCollection: collectionView)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debugWindow.configure()
        viewModel.input.send(.viewDidLoad)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// stop session
        viewModel.input.send(.stopSession)
    }
    
    private func hideDebugWindow(_ isHidden: Bool) {
        self.debugWindow.isHidden.toggle()
    }
    private func toggleMenuTopBottom() {
        debugWindowBottomConstraint.isActive.toggle()
        debugWindowTopConstraint.isActive.toggle()
        view.layoutIfNeeded()
    }
}
