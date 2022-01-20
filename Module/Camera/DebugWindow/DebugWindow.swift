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
    enum Action {
        case populateMenuCollection
        case currentScale(MatrixCollection.GridScale)
        case forcedMode(EditorZoneSelection.Mode)
        case currentZoneInfo(EditorDescription)
    }
    enum Response {
        case scaleUpGrid
        case scaleDownGrid
        case shouldHideGrid(Bool)
        case hideDebug(isHidden: Bool)
        case resetMask
        case editorMode(EditorZoneSelection.Mode)
        case transformZone(x: Int, y: Int, w: Int, h: Int)
    }
}

final class DebugWindow: UIView, PerformanceMeasurmentProvider, PoseDetectorProvider {
    /// I/O
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    /// collections
    /// containers
    @IBOutlet private weak var contentView: UIView!
    /// main stacks
    @IBOutlet weak var superStack: UIStackView!
    @IBOutlet weak var zoneControlsStack: UIStackView!
    @IBOutlet weak var maskControlsStack: UIStackView!
    @IBOutlet weak var generalInfoStack: UIStackView!
    // MARK: - Zone edit controls
    /// position
    @IBOutlet weak var positionInfoStack: UIStackView!
    @IBOutlet weak var positionXLabel: UILabel!
    @IBOutlet weak var positionYLabel: UILabel!
    @IBOutlet weak var positionControlsStack: UIStackView!
    @IBOutlet weak var moveUpZoneButton: UIButton!
    @IBOutlet weak var moveDownZoneButton: UIButton!
    @IBOutlet weak var moveLeftZoneButton: UIButton!
    @IBOutlet weak var moveRightZoneButton: UIButton!
    @IBOutlet weak var scaleDownZoneButton: UIButton!
    @IBOutlet weak var scaleUpZoneButton: UIButton!
    /// scale
    @IBOutlet weak var scaleInfoStack: UIStackView!
    @IBOutlet weak var scaleInfoWidthLabel: UILabel!
    @IBOutlet weak var scaleInfoHeightLabel: UILabel!
    @IBOutlet weak var scaleUpAxisStack: UIStackView!
    @IBOutlet weak var scaleDownAxisStack: UIStackView!
    @IBOutlet weak var scaleUpWidthButton: UIButton!
    @IBOutlet weak var scaleDownWidthButton: UIButton!
    @IBOutlet weak var scaleUpHeightButton: UIButton!
    @IBOutlet weak var scaleDownHeightButton: UIButton!
    /// zone edit
    @IBOutlet weak var zoneEditStack: UIStackView!
    @IBOutlet weak var zoneEditAddButton: UIButton!
    @IBOutlet weak var zoneEditSelectButton: UIButton!
    @IBOutlet weak var zoneEditCloneButton: UIButton!
    @IBOutlet weak var zoneEditDrawButton: UIButton!
    @IBOutlet weak var zoneEditSoundButton: UIButton!
    @IBOutlet weak var zoneEditConfigButton: UIButton!
    @IBOutlet weak var zoneEditDeleteButton: UIButton!
    @IBOutlet weak var zoneEditPreviousButton: UIButton!
    @IBOutlet weak var zoneEditNextButton: UIButton!
    @IBOutlet weak var zoneEditResetButton: UIButton!
    @IBOutlet weak var zoneEditCommitButton: UIButton!

    // MARK: - Zone edit controls
    @IBOutlet private weak var hideEverythingButton: UIButton!
    @IBOutlet private weak var detectionSettingButton: UIButton!
    @IBOutlet weak var performanceInfoStack: UIStackView!
    @IBOutlet private weak var fpsLabel: UILabel!
    @IBOutlet private weak var currentGridScaleLabel: UILabel!
    @IBOutlet weak var zoneInfoStack: UIStackView!
    @IBOutlet private weak var zoneTitleLabel: UILabel!
    @IBOutlet weak var zoneOrderNumberLabel: UILabel!
    @IBOutlet weak var zoneSoundNameLabel: UILabel!
    @IBOutlet weak var zoneForceSoundStatusLabel: UILabel!
    @IBOutlet weak var zoneVolumeLabel: UILabel!
    @IBOutlet weak var zoneMuteGroupLabel: UILabel!
    @IBOutlet weak var zoneIsHiddenLabel: UILabel!
    @IBOutlet private weak var hideGrid: UIButton!
    /// mask edit
    @IBOutlet private weak var createNewMaskButton: UIButton!
    @IBOutlet private weak var switchMaskButton: UIButton!
    @IBOutlet private weak var resetMaskButton: UIButton!
    @IBOutlet private weak var saveMaskButton: UIButton!
    @IBOutlet private weak var exportMaskButton: UIButton!
    @IBOutlet private weak var importMaskButton: UIButton!
    @IBOutlet private weak var selectBackgroundSoundButton: UIButton!
    @IBOutlet private weak var maskSettingsButton: UIButton!

    // MARK: - General info
    /// current mask
    @IBOutlet weak var maskTitleLabel: UILabel!
    @IBOutlet weak var maskOrderNumberLabel: UILabel!
    @IBOutlet weak var maskZonesTotalLabel: UILabel!
    @IBOutlet weak var maskBackgroundSoundLabel: UILabel!
    @IBOutlet weak var maskTypeLabel: UILabel!
    @IBOutlet weak var maskBackgroundSoundVolumeLabel: UILabel!
    @IBOutlet weak var maskIsAllZonesForceSoundLabel: UILabel!
    @IBOutlet weak var maskIsAllZonesHiddenLabel: UILabel!
    @IBOutlet weak var maskTotalSizeLabel: UILabel!
    @IBOutlet weak var maskAverageSoundSizeLabel: UILabel!
    /// available resources
    @IBOutlet weak var totalZonesLabel: UILabel!
    @IBOutlet weak var defaultMasksCountLabel: UILabel!
    @IBOutlet weak var mask64CountLabel: UILabel!
    @IBOutlet weak var totalAvailableSoundsLabel: UILabel!
    @IBOutlet weak var totalAvailableSoundsMP3Label: UILabel!
    @IBOutlet weak var totalAvailableSoundsWAVLabel: UILabel!
    /// detector collection menu
    @IBOutlet private weak var menuCollectionView: UICollectionView!
    private lazy var collectionManager = DebugCollectionMenu(collectionView: self.menuCollectionView)
    private lazy var touchableViews: [UIView] = { [self.menuCollectionView] }()
    
    private var bag = Set<AnyCancellable>()
    private var isGridHidden: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in touchableViews {
            if let v = view.hitTest(view.convert(point, from: self), with: event) {
                return v
            }
        }
        return super.hitTest(point, with: event)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) {
            return true
        }
        for view in touchableViews {
            return !view.isHidden && view.point(inside: view.convert(point, from: self), with: event)
        }
        return false
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
        handleEditorMode(.select)
    }
}

// MARK: - Private

private extension DebugWindow {
    
    func configureCollectionMenu() {
        menuCollectionView.isHidden = true
        //menuCollectionView.isUserInteractionEnabled = false
        collectionManager.configure()
        collectionManager.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .didPressNode(let menuItem):
                self?.poseDetector.input.send(.targetLandmarksToggle([menuItem.landmark]))
            }
        }).store(in: &bag)
    }
    
    func handleInput() {
        /// view input actions
        input.sink(receiveValue: {  [weak self] action in
            switch action {
            case .populateMenuCollection:
                self?.collectionManager.input.send(.populateWithSections)
            case .currentScale(let currentScale):
                self?.updateCurrentScaleLabel(currentScale)
            case .forcedMode(let mode):
                self?.handleEditorMode(mode)
            case .currentZoneInfo(let selectedZoneInfo):
                self?.updateCurrentZoneDescriptions(selectedZoneInfo)
            }
        }).store(in: &bag)
        /// performance measurment
        performanceMeasurment.output.sink(receiveValue: { [weak self] response in
                switch response {
                case .measurement(let fps):
                    self?.fpsLabel.text = fps
                case _: break
                }
            }).store(in: &bag)
        /// hide menu button
        detectionSettingButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.showHideDetectionMenu()
        }).store(in: &bag)
        /// hide debug button
        hideEverythingButton.publisher().sink(receiveValue: { [weak self] _ in
                self?.output.send(.hideDebug(isHidden: true))
            }).store(in: &bag)
        /// hide sidebars
        hideGrid.publisher().sink(receiveValue: { [weak self] _ in
                self?.output.send(.shouldHideGrid(true))
            }).store(in: &bag)
        /// hide menu button
        resetMaskButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.resetMask)
            }).store(in: &bag)
        
        // MARK: - Edit zone mode controls
        /// selection
        zoneEditSelectButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.select)
                self?.output.send(.editorMode(.select))
            }).store(in: &bag)
        zoneEditAddButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.add)
                self?.output.send(.editorMode(.add))
                self?.output.send(.hideDebug(isHidden: true))
            }).store(in: &bag)
        zoneEditDrawButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.draw)
                self?.output.send(.editorMode(.draw))
                self?.output.send(.hideDebug(isHidden: true))
            }).store(in: &bag)
        zoneEditDeleteButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.handleEditorMode(.delete)
                self?.output.send(.editorMode(.delete))
            }).store(in: &bag)
        
        // MARK: - Position and Scale controls
        moveUpZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: -3, w: 0, h: 0))
        }).store(in: &bag)
        moveDownZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: 3, w: 0, h: 0))
        }).store(in: &bag)
        moveLeftZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: -3, y: 0, w: 0, h: 0))
        }).store(in: &bag)
        moveRightZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 3, y: 0, w: 0, h: 0))
        }).store(in: &bag)
        
        /// scale both axis
        scaleUpZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: 0, w: 1, h: 1))
        }).store(in: &bag)
        scaleDownZoneButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.transformZone(x: 0, y: 0, w: -1, h: -1))
        }).store(in: &bag)
    }
    
    func updateCurrentScaleLabel(_ scale: MatrixCollection.GridScale) {
        switch scale {
        case .scale8196: self.currentGridScaleLabel.text = "8196"
        case .scale2048: self.currentGridScaleLabel.text = "2048"
        case .scale1024: self.currentGridScaleLabel.text = "1024"
        case .scale256: self.currentGridScaleLabel.text = "256"
        case .scale32: self.currentGridScaleLabel.text = "32"
        }
    }
    
    private func handleEditorMode(_ mode: EditorZoneSelection.Mode) {
        [zoneEditSelectButton, zoneEditAddButton, zoneEditDrawButton,
         zoneEditSoundButton, zoneEditNextButton, zoneEditPreviousButton,
         zoneEditCloneButton, zoneEditResetButton, zoneEditConfigButton,
         zoneEditCommitButton, zoneEditDeleteButton].forEach { $0?.layer.borderWidth = 0 }
        switch mode {
        case .select:
            zoneEditSelectButton.layer.borderWidth = 3.0
            zoneEditSelectButton.layer.borderColor = UIColor.green.cgColor
            debugAction("SELECT")
        case .add:
            zoneEditAddButton.layer.borderWidth = 3.0
            zoneEditAddButton.layer.borderColor = UIColor.green.cgColor
            debugAction("ADD")
        case .draw:
            zoneEditDrawButton.layer.borderWidth = 3.0
            zoneEditDrawButton.layer.borderColor = UIColor.green.cgColor
            debugAction("DRAW", delay: 2)
        case .delete:
            zoneEditDeleteButton.layer.borderWidth = 3.0
            zoneEditDeleteButton.layer.borderColor = UIColor.green.cgColor
            debugAction("DELETE")
        case _: break
        }
    }
    
    private func updateCurrentZoneDescriptions(_ info: EditorDescription) {
        positionXLabel.text = info.positionX.description
        positionYLabel.text = info.positionY.description
        scaleInfoWidthLabel.text = info.scaleX.description
        scaleInfoHeightLabel.text = info.scaleY.description
        totalZonesLabel.text = info.zonesTotal.description
    }
    
    private func debugAction(_ msg: String, delay: TimeInterval = 1) {
        let label = UILabel(frame: CGRect(x: 0, y: 50, width: bounds.width, height: 150))
        label.text = msg
        label.font = .systemFont(ofSize: 70, weight: .black)
        label.textColor = .red
        label.alpha = 0.4
        label.textAlignment = .center
        label.center.x = superview!.center.x
        superview?.addSubview(label)
        UIView.animate(withDuration: 0.3, delay: delay, options: [.allowUserInteraction], animations: { [weak label] in
            label?.transform = label!.transform.scaledBy(x: 1, y: 0.01)
        }, completion: { [weak label] _ in
            label?.removeFromSuperview()
        })
    }
    
    private func showHideDetectionMenu() {
        self.menuCollectionView.isHidden.toggle()
    }
}
