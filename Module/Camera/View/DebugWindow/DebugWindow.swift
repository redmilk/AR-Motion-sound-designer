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
        case matrixCollectionPublisher(AnyPublisher<MatrixCollection.Response, Never>)
        case populateMenuCollection
    }
    enum Response {
        case scaleUpGrid
        case scaleDownGrid
        case shouldHideGrid(Bool)
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
    @IBOutlet private weak var debugTopStack: UIStackView!
    /// buttons / labels
    @IBOutlet weak var infoLabelStack: UIStackView!
    
    @IBOutlet private weak var hideMenuButton: UIButton!
    @IBOutlet private weak var hideGrid: UIButton!
    @IBOutlet private weak var scaleUpGridButton: UIButton!
    @IBOutlet private weak var currentGridScaleLabel: UILabel!
    @IBOutlet private weak var scaleDownGridButton: UIButton!
    @IBOutlet private weak var hideDebugButton: UIButton!
    @IBOutlet private weak var detectionTimeLabel: UILabel!
    @IBOutlet private weak var fpsLabel: UILabel!

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
        input.receive(on: DispatchQueue.main)
            .sink(receiveValue: {  [weak self] action in
            switch action {
            case .matrixCollectionPublisher(let matrixOut):
                self?.subscribeMatrixOut(matrixOut: matrixOut)
            case .populateMenuCollection:
                self?.collectionManager.inp.send(.populateWithSections)
            }
        })
        .store(in: &bag)
        
        /// collection menu manager out
        collectionManager.out
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .didPressNode(let menuItem):
                    self?.poseDetector.input.send(.targetLandmarksToggle([menuItem.landmark]))
                }
            })
            .store(in: &bag)
        
        
        /// performance measurment
        performanceMeasurment.output
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] response in
                switch response {
                case .measurement(let fps):
                    self?.fpsLabel.text = fps
                case _: break
                }
            })
            .store(in: &bag)
        /// scale grid
        scaleUpGridButton.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.scaleUpGrid)
            })
            .store(in: &bag)
        /// scale grid
        scaleDownGridButton.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.output.send(.scaleUpGrid)
            })
            .store(in: &bag)
        /// hide menu button
        hideMenuButton.publisher().receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.menuCollectionView.isHidden.toggle()
                self?.menuCollectionView.isUserInteractionEnabled.toggle()
            })
            .store(in: &bag)
        /// hide debug button
        hideDebugButton.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.infoLabelStack.isHidden.toggle()
                self?.debugTopStack.isHidden.toggle()
                self?.hideDebugButton?.alpha = self?.debugTopStack.isHidden ?? false ? 0.4 : 1.0
                self?.menuCollectionView.isHidden = true
                self?.menuCollectionView.isUserInteractionEnabled = false
            })
            .store(in: &bag)
        /// hide sidebars
        hideGrid.publisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in
                self?.isGridHidden.toggle()
                self?.output.send(.shouldHideGrid(self?.isGridHidden ?? false))
            })
            .store(in: &bag)
    }
    
    func subscribeMatrixOut(matrixOut: AnyPublisher<MatrixCollection.Response, Never>) {
        matrixOut
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { response  in
            switch response {
            case .currentScale(let currentScale):
                switch currentScale {
                case .scale8196: self.currentGridScaleLabel.text = "8196"
                case .scale2048: self.currentGridScaleLabel.text = "2048"
                case .scale1024: self.currentGridScaleLabel.text = "1024"
                case .scale256: self.currentGridScaleLabel.text = "256"
                case .scale64: self.currentGridScaleLabel.text = "64"
                }
            case _: break
            }
        })
        .store(in: &bag)
    }
}
