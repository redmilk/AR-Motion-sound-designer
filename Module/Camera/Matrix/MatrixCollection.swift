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
fileprivate let itemSize2048: CGFloat = 10
fileprivate let groupHeight2048: CGFloat = 10
fileprivate let groupItemsCount2048: Int = 32

final class MatrixCollection: NSObject, MaskManagerProvider { /// NSObject for collection delegate
 
    enum Action {
        case initialSetup(isGridHidden: Bool)
        case shouldHideGrid(Bool)
        case drawZone([SoundZone: ZoneValue])
        case drawMask([SoundZone: ZoneValue])
        case removeAll(shouldHideGrid: Bool)
        case deleteZone([SoundZone: ZoneValue])
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<MatrixSection, MatrixNode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<MatrixSection, MatrixNode>
    
    let input = PassthroughSubject<Action, Never>()
    ///let output = PassthroughSubject<(), Never>()
    
    static var numberOfLinesBasedOnDeviceHeight: Int {
        let heightWithSafeAreaTopBottom = Int(UIScreen.main.bounds.height - 32 - 44)
        let dividableByTen = heightWithSafeAreaTopBottom - (heightWithSafeAreaTopBottom % 10)
        let linesCount = dividableByTen / 10
        return linesCount
    }
    
    private var isGridHidden: Bool = false
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!
    private var bag = Set<AnyCancellable>()
    private var gridContent = NSMutableDictionary()

    
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
            case .initialSetup(let isGridHidden):
                self.isGridHidden = isGridHidden
                self.configure()
                self.fillCollection(isGridHidden: isGridHidden)
            case .shouldHideGrid(let isGridHidden):
                self.isGridHidden = isGridHidden
                self.fillCollection(isGridHidden: self.isGridHidden)
            case .drawZone(let zone):
                self.drawZone(zone)
            case .drawMask(let zones):
                self.drawMask(zones)
            case .removeAll(let shouldHideGrid):
                self.removeAll()
                self.fillCollection(isGridHidden: shouldHideGrid)
            case .deleteZone(let zone):
                self.deleteZone(zone)
            }
        }).store(in: &bag)
    }
    
    private func emitNodes(lines: Int, rows: Int, isGridHidden: Bool = true, isPainted: UIColor? = nil) -> [MatrixSection] {
        var sections: [MatrixSection] = []
        for i in 0...lines - 1 {
            var items: [MatrixNode] = []
            for j in 0...rows - 1 {
                let ip = IndexPath(row: j, section: i)
                let colorIfZone = maskManager.activeMaskData?.determinateIndexPathZoneColor(ip)
                let item = MatrixNode(isGridHidden: isGridHidden, painted: colorIfZone ?? .clear)
                items.append(item)
            }
            let section = MatrixSection(nodes: items, id: UUID().uuidString)
            sections.append(section)
            gridContent.setObject(items as NSArray, forKey: section)
        }
        return sections
    }
    
    private func fillCollection(isGridHidden: Bool) {
        layoutCollectionAsGrid(itemSize: itemSize2048, groupHeight: groupHeight2048, groupItemsCount: groupItemsCount2048)
        let linesCount = MatrixCollection.numberOfLinesBasedOnDeviceHeight
        replaceAllWithNewNodes(emitNodes(lines: linesCount, rows: 32, isGridHidden: isGridHidden))
        collectionView.reloadData()
    }
    
    private func drawZone(_ zone: [SoundZone: ZoneValue]) {
        guard let zone = zone.keys.first else { return }
        let indexPathList = zone.getAllIndexPathesInside()
        reloadItemsAtIndexPathList(indexPathList)
    }
    private func drawMask(_ zones: [SoundZone: ZoneValue]) {
        var currentSnapshot = dataSource.snapshot()
        for zone in zones {
            let key = zone.key
            var items: [MatrixNode] = []
            let indexPathList = key.getAllIndexPathesInside()
            items = indexPathList.compactMap { (self.collectionView.cellForItem(at: $0) as? MatrixNodeCell)?.node }
            items.forEach { $0.painted = zone.value.color }
            currentSnapshot.reloadItems(items)
        }
        dataSource.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func deleteZone(_ zone: [SoundZone: ZoneValue]) {
        guard let zone = zone.keys.first else { return }
        let indexPathList = zone.getAllIndexPathesInside()
        reloadItemsAtIndexPathList(indexPathList, isDeletion: true)
    }
    
    private func reloadItemsAtIndexPathList(_ indexPathList: [IndexPath], isDeletion: Bool = false) {
        var currentSnapshot = dataSource.snapshot()
        var items: [MatrixNode] = []
        items = indexPathList.compactMap { (self.collectionView.cellForItem(at: $0) as? MatrixNodeCell)?.node }
        // MARK: - Zone pixels color
        //items.forEach { $0.painted = isDeletion ? .clear : .random }
        currentSnapshot.reloadItems(items)
        dataSource.apply(currentSnapshot, animatingDifferences: true)
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
    
    private func removeAll() {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.deleteAllItems()
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func reloadSection() {
        let currentSnapshot = dataSource.snapshot()
        dataSource?.apply(currentSnapshot, animatingDifferences: false)
    }
    
    private func buildDataSource() -> DataSource {
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

