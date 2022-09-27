//
//  EditorZoneSelection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 27.12.2021.
//

import Combine
import UIKit

fileprivate let editorMaxX: Int = 31
fileprivate let editorMaxY: Int = MatrixCollection.numberOfLinesBasedOnDeviceHeight

extension EditorZoneSelection {
    enum Mode: Equatable {
        case idle
        case add
        case clone(w: Int, h: Int)
        case draw
        case delete
    }
    enum Input {
        case resetMask
        case mode(Mode)
        case transformZone(x: Int, y: Int, w: Int, h: Int)
        case soundForCurrentZone(String)
        case undo
        case nextTemplate
        case prevTemplate
        case setupMask(MaskBase)
    }
    enum Output {
        case showAlert(message: String, title: String, button: String?)
    }
}

// MARK: - Editor Zone Selection
final class EditorZoneSelection: NSObject, InteractionFeedbackService {
    /// editor mask
    var mask = MaskBase()
    
    let input = PassthroughSubject<Input, Never>()
    let output = PassthroughSubject<Output, Never>()
    let currentSelectedZoneInfoPub = PassthroughSubject<EditorDescription, Never>()
    let selectedZoneRectPub = PassthroughSubject<CGRect, Never>()
    let modeSwitchPub = PassthroughSubject<EditorZoneSelection.Mode, Never>()
    let newZonePub = PassthroughSubject<[SoundZone: ZoneValue], Never>()
    let interactionFeedbackPub = PassthroughSubject<CGPoint, Never>()
    let openEditorPub = PassthroughSubject<(), Never>()
    let deleteZonePub = PassthroughSubject<[SoundZone: ZoneValue], Never>()
    
    private var bag = Set<AnyCancellable>()
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private let menuTapRecognizer = UITapGestureRecognizer()
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private var recognizersContainer: UIView!
    private var gridCollection: UICollectionView!
    private var previouslyAddedZones: [SoundZone] = []
    private var initialPoint: CGPoint?
    private var panGestureAnchorPoint: CGPoint?
    
    private var currentZone: [SoundZone: ZoneValue]? {
        didSet {
            guard let zone = currentZone?.keys.first, let value = currentZone?[zone] else {
                return Logger.log("Current zone - E M P T Y", type: .editor)
            }
            let soundDebugText = value.soundName.isEmpty ? "EMPTY" : value.soundName
            Logger.log("Current zone - Sound: \(soundDebugText) Min X: \(zone.minX) Max Y: \(zone.maxY)", type: .editor)
            let zoneInfo = EditorDescription(
                positionX: zone.minX, positionY: zone.minY,
                scaleX: max(1, zone.maxX - zone.minX), scaleY: max(1, zone.maxY - zone.minY),
                zonesTotal: mask.zonePresets.count, orderNumber: nil, zoneTitle: nil, sound: value.soundName)
            currentSelectedZoneInfoPub.send(zoneInfo)
            guard mode == .idle else { return }
            ZoneBaseAudio.shared.playSoundForZone(with: value.soundName)
        }
    }
    
    // MARK: - Editor's current mode
    private var mode: Mode = .idle {
        didSet {
            Logger.log(String(describing: mode), type: .editor)
        }
    }
        
    func configure(withView view: UIView, gridCollection: UICollectionView) {
        recognizersContainer = view
        self.gridCollection = gridCollection
        /// pan recognizer
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        recognizersContainer.addGestureRecognizer(panGestureRecognizer)
        /// edge pan recognizer
        menuTapRecognizer.addTarget(self, action: #selector(handleManyFingersTapForMenu(_:)))
        menuTapRecognizer.numberOfTouchesRequired = 2
        recognizersContainer.addGestureRecognizer(menuTapRecognizer)
        menuTapRecognizer.delegate = self
        recognizersContainer.addGestureRecognizer(tapGestureRecognizer)
        /// tap gesture
        tapGestureRecognizer.addTarget(self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        recognizersContainer.addGestureRecognizer(tapGestureRecognizer)
        
        input.sink(receiveValue: { [weak self] request in
            switch request {
            case .resetMask:
                self?.mask.zonePresets.removeAll()
                self?.recognizersContainer.layer.sublayers?.removeAll()
            case .mode(let mode):
                self?.mode = mode
            case .transformZone(let x, let y, let w, let h):
                self?.moveAndScaleZone(x: x, y: y, w: w, h: h)
                guard let self = self else { return }
                switch self.mode {
                    case .clone(let width, let height):
                        self.mode = .clone(w: width + w, h: height + h)
                        self.modeSwitchPub.send(self.mode)
                    case _: break
                    }
            case .soundForCurrentZone(let soundName):
                guard let zone = self?.currentZone, let key = zone.keys.first,
                      var value = self?.mask.zonePresets[key] else { return }
                value.soundName = soundName
                self?.mask.zonePresets[key] = value
                self?.currentZone = [key: value]
            case .undo:
                self?.undoAction()
            case .nextTemplate:
                break
            case .prevTemplate:
                break
            case .setupMask(let mask):
                self?.mask = mask
                guard let zone = mask.zonePresets.first else { return }
                self?.currentZone = [zone.key: zone.value]
                self?.trySelectZoneWithIndexPath(IndexPath(row: zone.key.minX, section: zone.key.minY))
            }
        }).store(in: &bag)
    }
    
    private func addZone(soundName: String = "", minX: Int, maxX: Int, minY: Int, maxY: Int) {
        let zone = SoundZone(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
        let value = ZoneValue(soundName: soundName, color: .clear)
        mask.zonePresets[zone] = value
        previouslyAddedZones.append(zone)
        currentZone = [zone: value]
        newZonePub.send([zone: value])
        
        if mode == .draw || mode == .add {
            trySelectZoneWithIndexPath(IndexPath(row: minX, section: maxY))
        }
    }
    
    private func moveAndScaleZone(x: Int = 0, y: Int = 0, w: Int = 0, h: Int = 0) {
        guard let zone = currentZone, let key = currentZone?.keys.first else { return }
        let newZone = zone
        var soundZone = newZone.keys.first!
        let zoneValue = newZone.values.first!
        
        deleteZonePub.send(zone)
        currentZone = nil
        mask.zonePresets[key] = nil
        
        soundZone.minX += x
        soundZone.maxX += x
        soundZone.minY += y
        soundZone.maxY += y
        
        soundZone.minX -= w
        soundZone.maxX += w
        soundZone.minY -= h
        soundZone.maxY += h

        let updatedZone = [soundZone: zoneValue]
        currentZone = updatedZone
        newZonePub.send(updatedZone)
        mask.zonePresets[soundZone] = zoneValue
        
        trySelectZoneWithIndexPath(IndexPath(row: soundZone.minX, section: soundZone.minY))
    }
    
    private func undoAction() {
        guard let lastAddedZoneKey = previouslyAddedZones.last,
              let lastAddedZone = mask.zonePresets[lastAddedZoneKey] else { return }
        currentZone = nil
        previouslyAddedZones.removeLast()
        deleteZonePub.send([lastAddedZoneKey: lastAddedZone])
        mask.zonePresets[lastAddedZoneKey] = nil
        recognizersContainer.layer.sublayers?.removeAll()
        guard let lastAddedZoneKey = previouslyAddedZones.last,
              let lastAddedZone = mask.zonePresets[lastAddedZoneKey] else { return }
        currentZone = [lastAddedZoneKey: lastAddedZone]
        trySelectZoneWithIndexPath(IndexPath(row: lastAddedZoneKey.minX, section: lastAddedZoneKey.minY))
    }
    
    // TODO: - refactor
    private func trySelectZoneWithIndexPath(_ indexPath: IndexPath) {
        guard let zone = mask.determinateZone(with: indexPath),
              let cornerIndexPathList = zone.keys.first?.getCornersIndexPathList() else { return }
        
        guard let firstCell = self.gridCollection.cellForItem(at: cornerIndexPathList.first!) as? MatrixNodeCell,
              let secondCell = self.gridCollection.cellForItem(at: cornerIndexPathList.last!) as? MatrixNodeCell else { return }
        let minPoint = CGPoint(x: min(firstCell.frame.minX, secondCell.frame.minX),
                               y: min(firstCell.frame.minY, secondCell.frame.minY))
        let maxPoint = CGPoint(x: max(firstCell.frame.maxX, secondCell.frame.maxX),
                               y: max(firstCell.frame.maxY, secondCell.frame.maxY))
        let selectedZoneRect = CGRect(x: minPoint.x, y: minPoint.y,
                                      width: max(1, maxPoint.x - minPoint.x), height: max(1, maxPoint.y - minPoint.y))
        currentZone = zone
        recognizersContainer.layer.sublayers?.removeAll()
        selectedZoneRectPub.send(selectedZoneRect)
    }
    private func trySelectZoneWithPoint(_ point: CGPoint) {
        guard let indexPath = gridCollection.indexPathForItem(at: point),
              let zone = mask.determinateZone(with: indexPath),
              let cornerIndexPathList = zone.keys.first?.getCornersIndexPathList() else { return }
        
        guard let firstCell = self.gridCollection.cellForItem(at: cornerIndexPathList.first!) as? MatrixNodeCell,
              let secondCell = self.gridCollection.cellForItem(at: cornerIndexPathList.last!) as? MatrixNodeCell else { return }
        let minPoint = CGPoint(x: min(firstCell.frame.minX, secondCell.frame.minX),
                               y: min(firstCell.frame.minY, secondCell.frame.minY))
        let maxPoint = CGPoint(x: max(firstCell.frame.maxX, secondCell.frame.maxX),
                               y: max(firstCell.frame.maxY, secondCell.frame.maxY))
        let selectedZoneRect = CGRect(x: minPoint.x, y: minPoint.y,
                                      width: max(1, maxPoint.x - minPoint.x), height: max(1, maxPoint.y - minPoint.y))
        currentZone = zone
        recognizersContainer.layer.sublayers?.removeAll()
        selectedZoneRectPub.send(selectedZoneRect)
    }
    
    // MARK: - Gestures
    
    @objc private func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        guard tapGestureRecognizer === gestureRecognizer else { return }
        let point = gestureRecognizer.location(in: recognizersContainer)
        switch mode {
        case .idle:
            trySelectZoneWithPoint(point)
            ///openEditorPub.send()
        case .add, .draw:
//            guard let tapIndexPath = gridCollection.indexPathForItem(at: point) else { return }
//            addZone(minX: tapIndexPath.row,
//                    maxX: tapIndexPath.row,
//                    minY: tapIndexPath.section,
//                    maxY: tapIndexPath.section)
            trySelectZoneWithPoint(point)
        case .clone(let width, let height):
            guard let tapIndexPath = gridCollection.indexPathForItem(at: point) else { return }
            addZone(minX: tapIndexPath.row,
                    maxX: max(1, tapIndexPath.row + width - 1),
                    minY: tapIndexPath.section,
                    maxY: max(1, tapIndexPath.section + height - 1))
            trySelectZoneWithPoint(point)
        case .delete:
            guard let indexPath = gridCollection.indexPathForItem(at: point),
                  let zone = mask.determinateZone(with: indexPath),
                  let zoneKey = zone.keys.first else { return }
            mask.zonePresets[zoneKey] = nil
            currentZone = nil
            deleteZonePub.send(zone)
            recognizersContainer.layer.sublayers?.removeAll()
        }
    }
    
    @objc private func handleManyFingersTapForMenu(_ gestureRecognizer: UITapGestureRecognizer) {
        guard menuTapRecognizer === gestureRecognizer else { return }
        openEditorPub.send(())
        generateInteractionFeedback()
    }

    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard panGestureRecognizer === gestureRecognizer else { return }
        switch gestureRecognizer.state {
        case .began:
            initialPoint = gestureRecognizer.location(in: recognizersContainer)
            panGestureAnchorPoint = gestureRecognizer.location(in: recognizersContainer)
            generateInteractionFeedback()
        case .changed:
            let gesturePoint = gestureRecognizer.location(in: recognizersContainer)
            self.interactionFeedbackPub.send(gesturePoint)
            panGestureAnchorPoint = gesturePoint
            guard mode == .idle else { return }
            if let indexPath = gridCollection.indexPathForItem(at: gesturePoint),
               let soundName = mask.determinateSoundForZonesWithIndexPath(indexPath) {
                ZoneBaseAudio.shared.playSoundForZone(with: soundName)
            }
        case .cancelled, .ended:
            addZoneWithPanGestureResult()
            generateInteractionFeedback()
        case _: break
        }
    }
    
    private func addZoneWithPanGestureResult() {
        guard mode == .add || mode == .draw,
              let lastPoint = panGestureAnchorPoint,
              let initialPoint = initialPoint,
              let initialIndexPath = gridCollection.indexPathForItem(at: initialPoint),
              let lastIndexPath = gridCollection.indexPathForItem(at: lastPoint) else { return }
        let minIndexPath = min(initialIndexPath, lastIndexPath)
        let maxIndexPath = max(initialIndexPath, lastIndexPath)
        addZone(minX: minIndexPath.row,
                maxX: maxIndexPath.row,
                minY: minIndexPath.section,
                maxY: maxIndexPath.section)
        panGestureAnchorPoint = nil
        self.initialPoint = nil
    }
    
    private func switchToCloneModeIfNeeded(w: Int, h: Int) {
        if mode == .add {
            mode = .clone(w: w, h: h)
            modeSwitchPub.send(.clone(w: w, h: h))
        }
    }
}

extension EditorZoneSelection: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if (otherGestureRecognizer == tapGestureRecognizer ||
            otherGestureRecognizer == panGestureRecognizer) &&
            gestureRecognizer == menuTapRecognizer {
            return false
        }
        if (gestureRecognizer == panGestureRecognizer || gestureRecognizer == tapGestureRecognizer) &&
            otherGestureRecognizer == tapGestureRecognizer || otherGestureRecognizer == panGestureRecognizer {
            return false
        }
        return true
    }
}
