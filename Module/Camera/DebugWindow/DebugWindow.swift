//
//  DebugWindow.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 16.12.2021.
//

import Foundation
import UIKit
import Combine

extension DebugWindow {
    enum Input {
        case populateMenuCollection
        case forcedMode(EditorZoneSelection.Mode)
        case currentZoneInfo(EditorDescription)
        case toggleFlipMenu
        case displaySelectedMaskDescriptionsModel(MaskDescription)
    }
    enum Response {
        case shouldHideGrid(Bool)
        case hideDebug(Bool)
        case resetMask
        case editorMode(EditorZoneSelection.Mode)
        case transformZone(x: Int, y: Int, w: Int, h: Int)
        case soundForZone(String)
        case maskSaveAndExport
        case maskImportFromPasteboard
        case toggleCamera
        case toggleFlipMenu
        case undoAction
        case nextTemplate
        case prevTemplate
    }
}

final class DebugWindow: UIView, PerformanceMeasurmentProvider, PoseDetectorProvider, MaskEditorProvider, MaskManagerProvider {
    let input = PassthroughSubject<Input, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    @IBOutlet private weak var contentView: UIView!
    // MARK: - Container stack views
    @IBOutlet weak var superStack: UIStackView!
    @IBOutlet weak var zoneControlsStack: UIStackView!
    @IBOutlet weak var maskControlsStack: UIStackView!
    @IBOutlet weak var generalInfoStack: UIStackView!
    // MARK: - Editor controls
    @IBOutlet private weak var detectionLandmarksSelectButton: TapAnimatedButton!
    @IBOutlet private weak var menuCollectionView: UICollectionView!
    // MARK: - Zone ransform
    @IBOutlet weak var positionInfoStack: UIStackView!
    @IBOutlet weak var positionXLabel: UILabel!
    @IBOutlet weak var positionYLabel: UILabel!
    @IBOutlet weak var positionControlsStack: UIStackView!
    @IBOutlet weak var moveUpZoneButton: TapAnimatedButton!
    @IBOutlet weak var moveDownZoneButton: TapAnimatedButton!
    @IBOutlet weak var moveLeftZoneButton: TapAnimatedButton!
    @IBOutlet weak var moveRightZoneButton: TapAnimatedButton!
    @IBOutlet weak var scaleDownZoneButton: TapAnimatedButton!
    @IBOutlet weak var scaleUpZoneButton: TapAnimatedButton!
    // MARK: - Zone axis scale
    @IBOutlet weak var scaleInfoStack: UIStackView!
    @IBOutlet weak var scaleInfoWidthLabel: UILabel!
    @IBOutlet weak var scaleInfoHeightLabel: UILabel!
    @IBOutlet weak var scaleUpAxisStack: UIStackView!
    @IBOutlet weak var scaleUpWidthButton: TapAnimatedButton!
    @IBOutlet weak var scaleDownWidthButton: TapAnimatedButton!
    @IBOutlet weak var scaleUpHeightButton: TapAnimatedButton!
    @IBOutlet weak var scaleDownHeightButton: TapAnimatedButton!
    // MARK: - Zone management controls
    @IBOutlet weak var zoneEditStack: UIStackView!
    @IBOutlet weak var zoneEditFirstStack: UIStackView!
    @IBOutlet weak var zoneEditSecondStack: UIStackView!
    @IBOutlet weak var zoneEditThirdStack: UIStackView!
    @IBOutlet weak var zoneEditAddButton: TapAnimatedButton!
    @IBOutlet weak var zoneEditCloneButton: TapAnimatedButton!
    
    @IBOutlet weak var zoneEditAlignmentButton: TapAnimatedButton!
    @IBOutlet weak var zoneEditDrawButton: TapAnimatedButton!
    @IBOutlet weak var zoneEditSoundButton: TapAnimatedButton!
    @IBOutlet weak var zoneEditConfigButton: TapAnimatedButton!
    @IBOutlet weak var zoneEditDeleteButton: TapAnimatedButton!
    @IBOutlet weak var previousTemplateButton: TapAnimatedButton!
    @IBOutlet weak var nextTemplateButton: TapAnimatedButton!
    @IBOutlet weak var undoButton: TapAnimatedButton!
    @IBOutlet weak var tryItButtonn: TapAnimatedButton!
    @IBOutlet weak var idleModeButton: TapAnimatedButton!
    
    @IBOutlet weak var forcePlayButton: TapAnimatedButton!
    // MARK: - Zone edit controls
    @IBOutlet private weak var fpsLabel: UILabel!
    @IBOutlet weak var zoneInfoStack: UIStackView!
    @IBOutlet weak var zoneSoundNameLabel: UILabel!
    @IBOutlet weak var zoneForceSoundStatusLabel: UILabel!
    @IBOutlet weak var zoneVolumeLabel: UILabel!
    @IBOutlet weak var zoneMuteGroupLabel: UILabel!
    // MARK: - Mask edit controls
    @IBOutlet private weak var createNewMaskButton: TapAnimatedButton!
    @IBOutlet private weak var resetMaskButton: TapAnimatedButton!
    @IBOutlet private weak var saveMaskButton: TapAnimatedButton!
    @IBOutlet private weak var exportMaskButton: TapAnimatedButton!
    @IBOutlet private weak var importMaskButton: TapAnimatedButton!
    @IBOutlet private weak var maskSettingsButton: TapAnimatedButton!
    // MARK: - Mask debug descriptions
    @IBOutlet weak var maskTitleLabel: UILabel!
    @IBOutlet weak var maskZonesTotalLabel: UILabel!
    @IBOutlet weak var maskBackgroundSoundLabel: UILabel!
    @IBOutlet weak var maskTypeLabel: UILabel!
    @IBOutlet weak var maskBackgroundSoundVolumeLabel: UILabel!
    @IBOutlet weak var maskIsAllZonesForceSoundLabel: UILabel!
    @IBOutlet weak var maskIsAllZonesHiddenLabel: UILabel!
    // MARK: - Other description labels
    @IBOutlet weak var defaultMasksCountLabel: UILabel!
    @IBOutlet weak var mask64CountLabel: UILabel!
    @IBOutlet weak var totalAvailableSoundsLabel: UILabel!
    @IBOutlet weak var totalAvailableSoundsMP3Label: UILabel!
    @IBOutlet weak var totalAvailableSoundsWAVLabel: UILabel!
    @IBOutlet weak var modeStatusLabel: UILabel!
    @IBOutlet weak var startCameraButton: UIButton!
    @IBOutlet weak var menuToggleFlipButton: TapAnimatedButton!
    @IBOutlet weak var menuBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuCloseButton: TapAnimatedButton!
    @IBOutlet weak var currentMaskOrderNumberLabel: UILabel!
    @IBOutlet weak var totalMasksCountLabel: UILabel!
    @IBOutlet weak var maskForcesAllSoundsLabel: UILabel!
    @IBOutlet weak var numberOfUniqueSoundsLabel: UILabel!
    @IBOutlet weak var numberOfZonesLabel: UILabel!
    @IBOutlet weak var currentMaskTypeAndOrigin: UILabel!
    
    private var bag = Set<AnyCancellable>()
    private lazy var collectionManager = DebugCollectionMenu(collectionView: self.menuCollectionView)
    // MARK: - Hit test interaction for collection menu
    private var isGridHidden: Bool = false
    
    // MARK: - Hit test handlers
    private lazy var touchableViews: [UIView] = { [self.menuCollectionView] }()
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in touchableViews {
            if let v = view.hitTest(view.convert(point, from: self), with: event) { return v }
        }
        return super.hitTest(point, with: event)
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        for view in touchableViews {
            return !view.isHidden && view.point(inside: view.convert(point, from: self), with: event)
        }
        return false
    }
    
    // MARK: - Init and configure
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    private func initView() {
        let bundle = Bundle(for: Self.self)
        bundle.loadNibNamed(String(describing: Self.self), owner: self, options: nil)
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    func configure() {
        handleInput()
        configureCollectionMenu()
        handleEditorMode(.idle)
    }
}

extension DebugWindow {
    // MARK: - Detection parts and sounds picker
    private func configureCollectionMenu() {
        menuCollectionView.isHidden = true
        collectionManager.configure()
        collectionManager.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .soundDidSelect(let menuItem):
                guard let soundName = menuItem.soundForZone else { return }
                Logger.log(soundName, type: .editor)
                ZoneBaseAudio.shared.playSoundForZone(with: soundName)
                self?.zoneSoundNameLabel.text = soundName
                self?.zoneSoundNameLabel.animateBackgroundChangeFromRandomToInitial()
                self?.output.send(.soundForZone(soundName))
            case .landmarkDidSelect(let menuItem):
                self?.poseDetector.input.send(.targetLandmarksToggle([menuItem.landmark]))
            }
        }).store(in: &bag)
    }
    private func handleInput() {
        input.sink(receiveValue: {  [weak self] action in
            switch action {
            case .populateMenuCollection:
                // MARK: - Populate with landmarks
                self?.collectionManager.input.send(.populateWithLandmarks)
            case .forcedMode(let mode):
                self?.handleEditorMode(mode)
            case .currentZoneInfo(let selectedZoneInfo):
                self?.updateCurrentZoneDebugLabels(selectedZoneInfo)
            case .toggleFlipMenu:
                self?.menuTopConstraint.isActive.toggle()
                self?.menuBottomConstraint.isActive.toggle()
            case .displaySelectedMaskDescriptionsModel(let descriptionsModel):
                self?.currentMaskOrderNumberLabel.text = descriptionsModel.orderNumber.description
                self?.totalMasksCountLabel.text = descriptionsModel.masksTotal.description
                self?.maskForcesAllSoundsLabel.text = descriptionsModel.shouldForcePlayAll ? "TRUE" : "FALSE"
                self?.numberOfUniqueSoundsLabel.text = descriptionsModel.currentMasksUniqueSoundsTotal.description
                self?.numberOfZonesLabel.text = descriptionsModel.currentMasksZonesTotal.description
                self?.currentMaskTypeAndOrigin.text = descriptionsModel.createdWith
            }
        }).store(in: &bag)
        performanceMeasurment.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .measurement(let fps):
                self?.fpsLabel.text = fps
            case _: break
            }
        }).store(in: &bag)
        detectionLandmarksSelectButton.publisher()
            .sink(receiveValue: { [weak self] _ in
            self?.handleDebugMenuOpenClose(isForSounds: false)
        }).store(in: &bag)
        resetMaskButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.resetMask)
            }).store(in: &bag)
        startCameraButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.toggleCamera)
            self?.menuCollectionView.isHidden = true
            self?.output.send(.hideDebug(true))
        }).store(in: &bag)
        menuToggleFlipButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.toggleFlipMenu)
                self?.menuCollectionView.isHidden = true
            }).store(in: &bag)
        undoButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.undoAction)
            }).store(in: &bag)
        
        // MARK: - Mask management controls
        exportMaskButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.maskSaveAndExport)
        }).store(in: &bag)
        importMaskButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.maskImportFromPasteboard)
        }).store(in: &bag)
        nextTemplateButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.nextTemplate)
        }).store(in: &bag)
        previousTemplateButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.prevTemplate)
        }).store(in: &bag)

        // MARK: - Modes for editing
        zoneEditDrawButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.draw)
                self?.output.send(.editorMode(.draw))
                self?.output.send(.hideDebug(true))
                self?.menuCollectionView.isHidden = true
            }).store(in: &bag)
        zoneEditDeleteButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.delete)
                self?.output.send(.editorMode(.delete))
                self?.menuCollectionView.isHidden = true
                self?.output.send(.hideDebug(true))
            }).store(in: &bag)
        zoneEditCloneButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.clone(w: 0, h: 0))
                self?.output.send(.editorMode(.clone(w: 0, h: 0)))
            }).store(in: &bag)
        zoneEditSoundButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.idle)
                self?.handleDebugMenuOpenClose(isForSounds: true)
            }).store(in: &bag)
        zoneEditAddButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.editorMode(.add))
                self?.handleEditorMode(.add)
            }).store(in: &bag)
        idleModeButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.editorMode(.idle))
                self?.handleEditorMode(.idle)
            }).store(in: &bag)
        forcePlayButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.maskManager.shouldForceplaySoundForCurrentMask.toggle()
            }).store(in: &bag)
        // MARK: - Position and Scale for zone
        moveUpZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: -1, w: 0, h: 0))
        }).store(in: &bag)
        moveDownZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: 1, w: 0, h: 0))
        }).store(in: &bag)
        moveLeftZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: -1, y: 0, w: 0, h: 0))
        }).store(in: &bag)
        moveRightZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 1, y: 0, w: 0, h: 0))
        }).store(in: &bag)
        scaleUpZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: 0, w: 1, h: 1))
        }).store(in: &bag)
        scaleDownZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: 0, w: -1, h: -1))
        }).store(in: &bag)
        
    }
    
    private func handleDebugMenuOpenClose(isForSounds: Bool) {
        let shouldHide = !menuCollectionView.isHidden
        isForSounds ? collectionManager.input.send(.populateWithSounds) :
        collectionManager.input.send(.populateWithLandmarks)
        menuCollectionView.isHidden = shouldHide
        guard !shouldHide else { return }
        handleEditorMode(.idle)
        output.send(.editorMode(.idle))
        let isAtTop = 0...100 ~= frame.minY
        menuTopConstraint.isActive = isAtTop
        menuBottomConstraint.isActive = !isAtTop
        layoutIfNeeded()
    }
    
    private func handleEditorMode(_ mode: EditorZoneSelection.Mode) {
        clearSelection()
        switch mode {
        case .add:
            zoneEditAddButton.layer.borderWidth = 2.0
            zoneEditAddButton.layer.borderColor = UIColor.white.cgColor
            zoneEditAddButton.layer.cornerRadius = 6.0
            modeStatusLabel.text = "ADD"
            debugAction("ADD", delay: 0.5)
        case .clone(let width, let height):
            zoneEditCloneButton.layer.borderWidth = 2.0
            zoneEditCloneButton.layer.borderColor = UIColor.white.cgColor
            zoneEditCloneButton.layer.cornerRadius = 6.0
            modeStatusLabel.text = "CLONE SIZE  W: \(width) H: \(height)"
            debugAction("CLONE", delay: 0.5)
        case .draw:
            zoneEditDrawButton.layer.borderWidth = 2.0
            zoneEditDrawButton.layer.borderColor = UIColor.white.cgColor
            zoneEditDrawButton.layer.cornerRadius = 6.0
            modeStatusLabel.text = "DRAW"
            debugAction("DRAW", delay: 0.5)
        case .delete:
            zoneEditDeleteButton.layer.borderWidth = 2.0
            zoneEditDeleteButton.layer.borderColor = UIColor.white.cgColor
            zoneEditDeleteButton.layer.cornerRadius = 6.0
            modeStatusLabel.text = "DELETE"
            debugAction("DELETE", delay: 0.5)
        case .idle:
            idleModeButton.layer.borderWidth = 2.0
            idleModeButton.layer.borderColor = UIColor.white.cgColor
            idleModeButton.layer.cornerRadius = 6.0
            modeStatusLabel.text = "IDLE"
            debugAction("IDLE", delay: 0.5)
        }
    }
    private func clearSelection() {
        zoneEditAddButton.layer.borderWidth = 0
        zoneEditCloneButton.layer.borderWidth = 0
        zoneEditDrawButton.layer.borderWidth = 0
        zoneEditDeleteButton.layer.borderWidth = 0
        idleModeButton.layer.borderWidth = 0
    }
    // MARK: - Description labels
    private func updateCurrentZoneDebugLabels(_ info: EditorDescription) {
        positionXLabel.text = info.positionX.description
        positionYLabel.text = info.positionY.description
        scaleInfoWidthLabel.text = info.scaleX.description
        scaleInfoHeightLabel.text = info.scaleY.description
        maskZonesTotalLabel.text = info.zonesTotal.description
        zoneSoundNameLabel.text = info.sound
    }
    private func debugAction(_ msg: String, delay: TimeInterval = 1) {
        return
        let debugCurrentModeLabel = UILabel(frame: CGRect(x: 0, y: 50, width: bounds.width, height: 150))
        debugCurrentModeLabel.text = msg
        debugCurrentModeLabel.font = .systemFont(ofSize: 70, weight: .light)
        debugCurrentModeLabel.textColor = .white
        debugCurrentModeLabel.alpha = 0.3
        debugCurrentModeLabel.textAlignment = .center
        debugCurrentModeLabel.center.x = superview!.center.x
        superview?.addSubview(debugCurrentModeLabel)
        UIView.animate(withDuration: 0.5, delay: delay, options: [.allowUserInteraction], animations: {
            [weak debugCurrentModeLabel] in
            debugCurrentModeLabel?.transform = debugCurrentModeLabel!.transform.scaledBy(x: 1, y: 0.01)
        }, completion: { _ in debugCurrentModeLabel.removeFromSuperview() })
    }
}
