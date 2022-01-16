//
//  DebugWindow.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 16.12.2021.
//

import Foundation
import UIKit
import Combine

/// I/O models
extension DebugWindow {
    enum Action {
        case populateMenuCollection
        case currentScale(MatrixCollection.GridScale)
    }
    enum Response {
        case scaleUpGrid
        case scaleDownGrid
        case shouldHideGrid(Bool)
        case hideDebug(isHidden: Bool)
        case resetMask
    }
}

final class DebugWindow: UIView, PerformanceMeasurmentProvider, PoseDetectorProvider {
    /// I/O
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    /// collections
    @IBOutlet private weak var menuCollectionView: UICollectionView!
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
    @IBOutlet weak var totalMasksCountLabel: UILabel!
    @IBOutlet weak var defaultMasksCountLabel: UILabel!
    @IBOutlet weak var mask64CountLabel: UILabel!
    @IBOutlet weak var totalAvailableSoundsLabel: UILabel!
    @IBOutlet weak var totalAvailableSoundsMP3Label: UILabel!
    @IBOutlet weak var totalAvailableSoundsWAVLabel: UILabel!
    /// detector collection menu
    @IBOutlet weak var menuHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuBottomToStackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuBottomToDebugConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuTopToDebugConstraint: NSLayoutConstraint!
    
    
    private var bag = Set<AnyCancellable>()
    private lazy var collectionManager = DebugCollectionMenu(collectionView: self.menuCollectionView)
    private var isGridHidden: Bool = false
    
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
    }
}

// MARK: - Private

private extension DebugWindow {
    
    func handleInput() {
        menuCollectionView.isHidden = true
        menuCollectionView.isUserInteractionEnabled = false
        collectionManager.configure()
        /// view input actions
        input
            .sink(receiveValue: {  [weak self] action in
            switch action {
            case .populateMenuCollection:
                self?.collectionManager.input.send(.populateWithSections)
            case .currentScale(let currentScale):
                self?.updateCurrentScaleLabel(currentScale)
            }
        })
        .store(in: &bag)
        
        /// collection menu manager out
        collectionManager.output
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .didPressNode(let menuItem):
                    self?.poseDetector.input.send(.targetLandmarksToggle([menuItem.landmark]))
                }
            })
            .store(in: &bag)
        
        
        /// performance measurment
        performanceMeasurment.output
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .measurement(let fps):
                    self?.fpsLabel.text = fps
                case _: break
                }
            })
            .store(in: &bag)
        /// hide menu button
        detectionSettingButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.menuCollectionView.isHidden.toggle()
                self?.menuCollectionView.isUserInteractionEnabled.toggle()
                if let isHidden = self?.menuCollectionView.isHidden {
                    self?.menuBottomToDebugConstraint.isActive = isHidden
                    self?.menuTopToDebugConstraint.isActive = isHidden
                    self?.layoutIfNeeded()
                }
            })
            .store(in: &bag)
        /// hide debug button
        hideEverythingButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.hideDebug(isHidden: true))
            })
            .store(in: &bag)
        /// hide sidebars
        hideGrid.publisher()
            .sink(receiveValue: { [weak self] _ in
               // self?.isGridHidden.toggle()
                self?.output.send(.shouldHideGrid(true))
            })
            .store(in: &bag)
        
        /// hide menu button
        resetMaskButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.resetMask)
            })
            .store(in: &bag)
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
}
