//
//  EditorZoneSelection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 27.12.2021.
//

import Combine
import UIKit

// MARK: - Mask for editor

final class EditorMask: MaskBase { }

// MARK: - Editor Zone Selection

final class EditorZoneSelection: NSObject {
    static let shared = EditorZoneSelection()
    
    enum Request {
        case resetMask
    }
    
    var mask = EditorMask()
    
    let requestSub = PassthroughSubject<Request, Never>()
    var newZonePub = PassthroughSubject<[SoundZone: ZoneValue], Never>()
    var interactionFeedbackPub = PassthroughSubject<CGPoint, Never>()
    var openEditorPub = PassthroughSubject<(), Never>()
    
    private var bag = Set<AnyCancellable>()
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private let edgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    private var panGestureContainer: UIView!
    private var initialPoint: CGPoint? {
        willSet {
            guard let newValue = newValue else { return }
            ///Logger.log("⬜️ initialPoint \(newValue.x), \(newValue.y)", type: .grid)
        }
    }
    private var panGestureAnchorPoint: CGPoint? {
        willSet {
            guard let newValue = newValue else { return }
            ///Logger.log("⬛️ \(newValue.x), \(newValue.y)", type: .grid)
        }
    }
    
    func configure(withView view: UIView, target: Any) {
        panGestureContainer = view
        /// pan recognizer
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureContainer.addGestureRecognizer(panGestureRecognizer)
        /// edge pan recognizer
        edgePanGestureRecognizer.addTarget(self, action: #selector(handleEdgePanGesture(sender:)))
        edgePanGestureRecognizer.edges = .left
        edgePanGestureRecognizer.maximumNumberOfTouches = 2
        edgePanGestureRecognizer.minimumNumberOfTouches = 2
        edgePanGestureRecognizer.delegate = self
        panGestureContainer.addGestureRecognizer(edgePanGestureRecognizer)
        ///
        
        requestSub.sink(receiveValue: { [weak self] request in
            switch request {
            case .resetMask:
                self?.mask.zonePresets.removeAll()
            }
        }).store(in: &bag)
    }
    
    private func addZone(soundName: String = "", minX: Int, maxX: Int, minY: Int, maxY: Int) {
        let zone = SoundZone(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
        let value = ZoneValue(icons: nil, soundName: soundName)
        mask.zonePresets[zone] = value
        newZonePub.send([zone: value])
    }
    
    private func selectZone() {
        
    }
    
    @objc func handleEdgePanGesture(sender: UIScreenEdgePanGestureRecognizer) {
        let translation = sender.translation(in: sender.view!)
        let isEnoughToTriggerX = UIScreen.main.bounds.width * 0.3
        if translation.x >= isEnoughToTriggerX {
            openEditorPub.send(())
        }
    }

    @objc private func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard panGestureRecognizer === gestureRecognizer else { assert(false) }

        switch gestureRecognizer.state {
        case .began:
            assert(panGestureAnchorPoint == nil)
            initialPoint = gestureRecognizer.location(in: panGestureContainer)
            panGestureAnchorPoint = gestureRecognizer.location(in: panGestureContainer)
        case .changed:
            let gesturePoint = gestureRecognizer.location(in: panGestureContainer)
            self.panGestureAnchorPoint = gesturePoint
            self.interactionFeedbackPub.send(gesturePoint)

        case .cancelled, .ended:
            
            guard let lastPoint = panGestureAnchorPoint, let initialPoint = initialPoint else { return }
            addZone(minX: Int(initialPoint.x.rounded(.down)),
                    maxX: Int(lastPoint.x.rounded(.down)),
                    minY: Int(initialPoint.y.rounded(.down)),
                    maxY: Int(lastPoint.y.rounded(.down)))
            
            panGestureAnchorPoint = nil
            self.initialPoint = nil

        case .failed, .possible:
            assert(panGestureAnchorPoint == nil)
        @unknown default: break
        }
    }
}

extension EditorZoneSelection: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == edgePanGestureRecognizer {
            return true
        }
        return false
    }
}
