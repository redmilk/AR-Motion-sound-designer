//
//  MatrixCollection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation
import Combine
import UIKit

/// 2048
let itemSize2048: CGFloat = 5
let groupHeight2048: CGFloat = 5
let groupItemsCount2048: Int = 64
/// 1024
let itemSize1024: CGFloat = 10
let groupHeight1024: CGFloat = 10
let groupItemsCount1024: Int = 32
/// 512
let itemSize512: CGFloat = 20
let groupHeight512: CGFloat = 20
let groupItemsCount512: Int = 16
/// 256
let itemSize256: CGFloat = 40
let groupHeight256: CGFloat = 40
let groupItemsCount256: Int = 8
/// 128
let itemSize128: CGFloat = 80
let groupHeight128: CGFloat = 80
let groupItemsCount128: Int = 4

final class MatrixCollection: NSObject { /// NSObject for collection delegate
    
    enum GridScale {
        case scale2048
        case scale1024
        case scale512
        case scale256
        case scale128
    }
    
    enum Action {
        case initialSetup
        case configureScaling(GridScale)
        case scaleUp
        case scaleDown
        ///case removeNodes([MatrixNode])
    }
    
    enum Response {
        case didPressNode(MatrixNode)
        case currentScale(GridScale)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<MatrixSection, MatrixNode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<MatrixSection, MatrixNode>
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
 
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!
    private var bag = Set<AnyCancellable>()
    private var currentScaleType: GridScale!
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        handleInput()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func configure() {
        collectionView.delegate = self
        collectionView.register(cellClassName: MatrixNodeCell.self)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.isPagingEnabled = false
        dataSource = buildDataSource()
    }
    
    private func handleInput() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .initialSetup:
                self.configure()
            case .configureScaling(let scaleType):
                self.setupScaleType(scaleType)
            case .scaleUp:
                switch self.currentScaleType! {
                case .scale2048:
                    self.setupScaleType(.scale128)
                case .scale1024:
                    self.setupScaleType(.scale2048)
                case .scale512:
                    self.setupScaleType(.scale1024)
                case .scale256:
                    self.setupScaleType(.scale512)
                case .scale128:
                    self.setupScaleType(.scale256)
                }
            case .scaleDown:
                switch self.currentScaleType! {
                case .scale2048:
                    self.setupScaleType(.scale1024)
                case .scale1024:
                    self.setupScaleType(.scale512)
                case .scale512:
                    self.setupScaleType(.scale256)
                case .scale256:
                    self.setupScaleType(.scale128)
                case .scale128:
                    self.setupScaleType(.scale1024)
                }
            }
        })
        .store(in: &bag)
    }
    
    private func emitNodes(_ count: Int) -> [MatrixNode] {
        var nodes: [MatrixNode] = []
        for _ in 1...count {
            let node = MatrixNode()
            nodes.append(node)
        }
        return nodes
    }
    
    private func setupScaleType(_ scaleType: GridScale) {
        self.currentScaleType = scaleType
        switch scaleType {
        case .scale2048:
            self.layoutCollectionAsGrid(itemSize: itemSize2048, groupHeight: groupHeight2048, groupItemsCount: groupItemsCount2048)
            self.replaceAllWithNewNodes(self.emitNodes(4096 * 2))
        case .scale1024:
            self.layoutCollectionAsGrid(itemSize: itemSize1024, groupHeight: groupHeight1024, groupItemsCount: groupItemsCount1024)
            self.replaceAllWithNewNodes(self.emitNodes(2048))
        case .scale512:
            self.layoutCollectionAsGrid(itemSize: itemSize512, groupHeight: groupHeight512, groupItemsCount: groupItemsCount512)
            self.replaceAllWithNewNodes(self.emitNodes(1024))
        case .scale256:
            self.layoutCollectionAsGrid(itemSize: itemSize256, groupHeight: groupHeight256, groupItemsCount: groupItemsCount256)
            self.replaceAllWithNewNodes(self.emitNodes(256))
        case .scale128:
            self.layoutCollectionAsGrid(itemSize: itemSize128, groupHeight: groupHeight128, groupItemsCount: groupItemsCount128)
            self.replaceAllWithNewNodes(self.emitNodes(64))
        }
        self.collectionView.reloadData()
        output.send(.currentScale(scaleType))
    }

    private func replaceAllWithNewNodes(_ nodes: [MatrixNode]) {
        var snapshot = Snapshot()
        let section = MatrixSection(nodes: [], id: UUID().uuidString)
        snapshot.appendSections([section])
        snapshot.appendItems(nodes, toSection: section)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func removeNodes(_ nodes: [MatrixNode]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.deleteItems(nodes)
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func reloadSection() {
        let currentSnapshot = dataSource.snapshot()
        dataSource?.apply(currentSnapshot, animatingDifferences: false)
    }
    
    private func reloadNodes(_ nodes: [MatrixNode]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.reloadItems(nodes)
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, dataBox) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: MatrixNodeCell.self),
                    for: indexPath) as! MatrixNodeCell
                return cell
            })
        return dataSource
    }

    private func layoutCollectionAsGrid(itemSize: CGFloat, groupHeight: CGFloat, groupItemsCount: Int) {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .absolute(itemSize), heightDimension: .absolute(itemSize))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(groupHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: groupItemsCount)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
    
    private func defineNodeByPoint(_ point: CGPoint) -> MatrixNode? {
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return nil }
        let cell = collectionView.cellForItem(at: indexPath) as! MatrixNodeCell
        return cell.node
    }
}

// MARK: - Internal
private extension MatrixCollection {
    func scrollToItem(withIndexPath indexPath: IndexPath) {
        Logger.log(indexPath.section.description + " " + indexPath.row.description, type: .all)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

extension MatrixCollection: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MatrixNodeCell else { return }
        cell.trigger()
    }
}

