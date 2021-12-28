//
//  MatrixCollection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation
import Combine
import UIKit

/// 8196
let itemSize8196: CGFloat = 5
let groupHeight8196: CGFloat = 5
let groupItemsCount8196: Int = 64
/// 2048
let itemSize2048: CGFloat = 10
let groupHeight2048: CGFloat = 10
let groupItemsCount2048: Int = 32
/// 1024
let itemSize1024: CGFloat = 20
let groupHeight1024: CGFloat = 20
let groupItemsCount1024: Int = 16
/// 256
let itemSize256: CGFloat = 40
let groupHeight256: CGFloat = 40
let groupItemsCount256: Int = 8
/// 32
let itemSize32: CGFloat = 80
let groupHeight32: CGFloat = 80
let groupItemsCount32: Int = 4

final class MatrixCollection: NSObject { /// NSObject for collection delegate
    
    enum GridScale {
        case scale8196
        case scale2048
        case scale1024
        case scale256
        case scale32
    }
    
    enum Action {
        case initialSetup
        case configureScaling(scale: GridScale, isGridHidden: Bool)
        case scaleUp
        case scaleDown
        case shouldHideGrid(Bool)
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
    private var isGridHidden: Bool = false
    
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
        input
            .sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .initialSetup:
                self.configure()
            case .configureScaling(let scaleType, let isGridHidden):
                self.isGridHidden = isGridHidden
                self.setupScaleType(scaleType, isVisibleGrid: self.isGridHidden)
            case .shouldHideGrid(let isGridHidden):
                self.isGridHidden = isGridHidden
                self.setupScaleType(self.currentScaleType, isVisibleGrid: self.isGridHidden)
            case .scaleUp:
                switch self.currentScaleType! {
                case .scale8196: break
                case .scale2048:
                    self.setupScaleType(.scale8196, isVisibleGrid: self.isGridHidden)
                case .scale1024:
                    self.setupScaleType(.scale2048, isVisibleGrid: self.isGridHidden)
                case .scale256:
                    self.setupScaleType(.scale1024, isVisibleGrid: self.isGridHidden)
                case .scale32:
                    self.setupScaleType(.scale256, isVisibleGrid: self.isGridHidden)
                }
            case .scaleDown:
                switch self.currentScaleType! {
                case .scale8196:
                    self.setupScaleType(.scale2048, isVisibleGrid: self.isGridHidden)
                case .scale2048:
                    self.setupScaleType(.scale1024, isVisibleGrid: self.isGridHidden)
                case .scale1024:
                    self.setupScaleType(.scale256, isVisibleGrid: self.isGridHidden)
                case .scale256:
                    self.setupScaleType(.scale32, isVisibleGrid: self.isGridHidden)
                case .scale32: break
                }
            }
        })
        .store(in: &bag)
    }
    
    private func emitNodes(lines: Int, rows: Int, isGridHidden: Bool = true) -> [MatrixSection] {
        var sections: [MatrixSection] = []
        for i in 0...lines - 1 {
            var items: [MatrixNode] = []
            for j in 0...rows - 1 {
                let isIndexPathBelongsToZone = MaskManager.shared.activeMaskData?.determinateIndexPathZoneColor(IndexPath(row: j, section: i))
                items.append(MatrixNode(isGridHidden: isGridHidden, debugColorIfNodeBelongsToZone: isIndexPathBelongsToZone))
            }
            let section = MatrixSection(nodes: items, id: UUID().uuidString)
            sections.append(section)
        }
        return sections
    }
    
    private func setupScaleType(_ scaleType: GridScale, isVisibleGrid: Bool) {
        self.currentScaleType = scaleType
        switch scaleType {
        case .scale8196:
            layoutCollectionAsGrid(itemSize: itemSize8196, groupHeight: groupHeight8196, groupItemsCount: groupItemsCount8196)
            replaceAllWithNewNodes(emitNodes(lines: 128, rows: 64, isGridHidden: isVisibleGrid))
        case .scale2048:
            layoutCollectionAsGrid(itemSize: itemSize2048, groupHeight: groupHeight2048, groupItemsCount: groupItemsCount2048)
            replaceAllWithNewNodes(emitNodes(lines: 64, rows: 32, isGridHidden: isVisibleGrid))
        case .scale1024:
            layoutCollectionAsGrid(itemSize: itemSize1024, groupHeight: groupHeight1024, groupItemsCount: groupItemsCount1024)
            replaceAllWithNewNodes(emitNodes(lines: 96, rows: 16, isGridHidden: isVisibleGrid))
        case .scale256:
            layoutCollectionAsGrid(itemSize: itemSize256, groupHeight: groupHeight256, groupItemsCount: groupItemsCount256)
            replaceAllWithNewNodes(emitNodes(lines: 32, rows: 8, isGridHidden: isVisibleGrid))
        case .scale32:
            layoutCollectionAsGrid(itemSize: itemSize32, groupHeight: groupHeight32, groupItemsCount: groupItemsCount32)
            replaceAllWithNewNodes(emitNodes(lines: 8, rows: 4, isGridHidden: isVisibleGrid))
        }
        collectionView.reloadData()
        output.send(.currentScale(scaleType))
    }

    private func replaceAllWithNewNodes(_ sections: [MatrixSection]) {
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(section.nodes, toSection: section)
        }
        let runLoopMode = CFRunLoopMode.commonModes.rawValue
        CFRunLoopPerformBlock(CFRunLoopGetMain(), runLoopMode) { [weak dataSource] in
            dataSource?.apply(snapshot, animatingDifferences: false)
        }
        CFRunLoopWakeUp(CFRunLoopGetMain())
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
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, node) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: MatrixNodeCell.self),
                    for: indexPath) as! MatrixNodeCell
                cell.node = node
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

