//
//  EditorZoneSelection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 27.12.2021.
//

import Combine
import UIKit

final class EditorMask: MaskBase { }

fileprivate let editorMaxX: Int = 31
fileprivate let editorMaxY: Int = MatrixCollection.numberOfLinesBasedOnDeviceHeight

extension EditorZoneSelection {
    enum Mode {
        case select
        case add
        case draw
        case delete
        case bindSound
    }
    enum Input {
        case resetMask
        case mode(Mode)
        case transformZone(x: Int, y: Int, w: Int, h: Int)
    }
}

// MARK: - Editor Zone Selection
final class EditorZoneSelection: NSObject {
    /// editor mask
    static var mask = EditorMask()
    
    let input = PassthroughSubject<Input, Never>()
    let currentSelectedZoneInfoPub = PassthroughSubject<EditorDescription, Never>()
    let selectedZoneRectPub = PassthroughSubject<CGRect, Never>()
    let modeSwitchPub = PassthroughSubject<EditorZoneSelection.Mode, Never>()
    let newZonePub = PassthroughSubject<[SoundZone: ZoneValue], Never>()
    let interactionFeedbackPub = PassthroughSubject<CGPoint, Never>()
    let openEditorPub = PassthroughSubject<(), Never>()
    let deleteZonePub = PassthroughSubject<[SoundZone: ZoneValue], Never>()
    private var bag = Set<AnyCancellable>()
    
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private let edgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    private let tapGestureRecognizer = UITapGestureRecognizer()
    private var recognizersContainer: UIView!
    private var gridCollection: UICollectionView!
    
    private var initialPoint: CGPoint?
    private var panGestureAnchorPoint: CGPoint?
    
    private var currentZone: [SoundZone: ZoneValue]? {
        didSet {
            guard let zone = currentZone?.keys.first else {
                return Logger.log("Current zone - E M P T Y", type: .editor)
            }
            Logger.log("Current zone - Min X: \(zone.minX) Max Y: \(zone.maxY)", type: .editor)
            let zoneInfo = EditorDescription(
                positionX: zone.minX, positionY: zone.minY,
                scaleX: max(1, zone.maxX - zone.minX), scaleY: max(1, zone.maxY - zone.minY),
                zonesTotal: EditorZoneSelection.mask.zonePresets.count, orderNumber: nil, zoneTitle: nil, sound: nil)
            currentSelectedZoneInfoPub.send(zoneInfo)
        }
    }
    
    // MARK: - Editor's current mode
    private var mode: Mode = .select {
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
        edgePanGestureRecognizer.addTarget(self, action: #selector(handleEdgePanGesture(_:)))
        edgePanGestureRecognizer.edges = .left
        edgePanGestureRecognizer.maximumNumberOfTouches = 2
        edgePanGestureRecognizer.minimumNumberOfTouches = 2
        edgePanGestureRecognizer.delegate = self
        recognizersContainer.addGestureRecognizer(edgePanGestureRecognizer)
        /// tap gesture
        tapGestureRecognizer.addTarget(self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        recognizersContainer.addGestureRecognizer(tapGestureRecognizer)
        
        input.sink(receiveValue: { [weak self] request in
            switch request {
            case .resetMask:
                EditorZoneSelection.mask.zonePresets.removeAll()
                self?.recognizersContainer.layer.sublayers?.removeAll()
            case .mode(let mode):
                self?.mode = mode
            case .transformZone(let x, let y, let w, let h):
                self?.moveAndScaleZone(x: x, y: y, w: w, h: h)
            }
        }).store(in: &bag)
    }
    
    private func addZone(soundName: String = "", minX: Int, maxX: Int, minY: Int, maxY: Int) {
        let zone = SoundZone(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
        let value = ZoneValue(icons: nil, soundName: soundName, color: .clear)
        EditorZoneSelection.mask.zonePresets[zone] = value
        currentZone = [zone: value]
        newZonePub.send([zone: value])
        
        if mode == .draw || mode == .add {
            trySelectZoneWithIndexPath(IndexPath(row: minX, section: maxY))
        }
        if mode == .add {
            openEditorPub.send()
        }
    }
    
    private func moveAndScaleZone(x: Int = 0, y: Int = 0, w: Int = 0, h: Int = 0) {
        guard let zone = currentZone, let key = currentZone?.keys.first else { return }
        let newZone = zone
        var soundZone = newZone.keys.first!
        var zoneValue = newZone.values.first!
        
        deleteZonePub.send(zone)
        currentZone = nil
        EditorZoneSelection.mask.zonePresets[key] = nil
        
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
        EditorZoneSelection.mask.zonePresets[soundZone] = zoneValue
        
        trySelectZoneWithIndexPath(IndexPath(row: soundZone.minX, section: soundZone.minY))
    }
    
    // MARK: - Selection with point or indexPath
    // TODO: - refactor
    private func trySelectZoneWithIndexPath(_ indexPath: IndexPath) {
        guard let zone = EditorZoneSelection.mask.determinateZone(with: indexPath),
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
              let zone = EditorZoneSelection.mask.determinateZone(with: indexPath),
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
    
    @objc private func handleTapGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard tapGestureRecognizer === gestureRecognizer else { assert(false) }
        let point = gestureRecognizer.location(in: recognizersContainer)
        switch mode {
        case .select:
            trySelectZoneWithPoint(point)
            openEditorPub.send()
        case .add, .draw:
            guard let tapIndexPath = gridCollection.indexPathForItem(at: point) else { return }
            addZone(minX: tapIndexPath.row,
                    maxX: tapIndexPath.row,
                    minY: tapIndexPath.section,
                    maxY: tapIndexPath.section)
            switchToSelectionModeIfNeeded()
        case .delete:
            guard let indexPath = gridCollection.indexPathForItem(at: point),
                  let zone = EditorZoneSelection.mask.determinateZone(with: indexPath),
                  let zoneKey = zone.keys.first else { return }
            EditorZoneSelection.mask.zonePresets[zoneKey] = nil
            currentZone = nil
            deleteZonePub.send(zone)
            recognizersContainer.layer.sublayers?.removeAll()
        case _: break
        }
    }
    
    @objc private func handleEdgePanGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard edgePanGestureRecognizer === gestureRecognizer else { assert(false) }
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!)
        let isEnoughToTriggerX = UIScreen.main.bounds.width * 0.3
        if translation.x >= isEnoughToTriggerX {
            openEditorPub.send(())
        }
    }

    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard panGestureRecognizer === gestureRecognizer else { assert(false) }
        switch gestureRecognizer.state {
        case .began:
            initialPoint = gestureRecognizer.location(in: recognizersContainer)
            panGestureAnchorPoint = gestureRecognizer.location(in: recognizersContainer)
        case .changed:
            let gesturePoint = gestureRecognizer.location(in: recognizersContainer)
            self.interactionFeedbackPub.send(gesturePoint)
            self.panGestureAnchorPoint = gesturePoint
        case .cancelled, .ended:
            addZoneWithPanGestureResult()
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
        switchToSelectionModeIfNeeded()
    }
    
    private func switchToSelectionModeIfNeeded() {
        if mode == .add {
            mode = .select
            modeSwitchPub.send(.select)
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
            gestureRecognizer == edgePanGestureRecognizer {
            return false
        }
        if (gestureRecognizer == panGestureRecognizer || gestureRecognizer == tapGestureRecognizer) &&
            otherGestureRecognizer == tapGestureRecognizer || otherGestureRecognizer == panGestureRecognizer {
            return false
        }
        return true
    }
}
