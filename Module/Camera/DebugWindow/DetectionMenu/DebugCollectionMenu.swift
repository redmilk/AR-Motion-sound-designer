//
//  DebugCollectionMenu.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import Foundation
import Combine
import UIKit

final class DebugCollectionMenu: NSObject { /// NSObject for collection delegate
    enum Action {
        case populateWithLandmarks
        case populateWithSounds
    }
    enum Response {
        case landmarkDidSelect(DebugMenuItem)
        case soundDidSelect(DebugMenuItem)
    }
    enum Content {
        case sounds
        case landmarks
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<DebugMenuSection, DebugMenuItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<DebugMenuSection, DebugMenuItem>
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
 
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!
    private var bag = Set<AnyCancellable>()
    private let sectionsProvider = DebugMenuSectionsDatasource()
    private var contentType: Content = .landmarks
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .populateWithLandmarks:
                self?.populateWithLandmarks()
                self?.contentType = .landmarks
            case .populateWithSounds:
                self?.populateWithSounds()
                self?.contentType = .sounds
            }
        })
        .store(in: &bag)
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func configure() {
        collectionView.delegate = self
        collectionView.register(cellClassName: DebugMenuCell.self)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.isPagingEnabled = false
        dataSource = buildDataSource()
        layoutCollection()
        ///populateWithLandmarks()
        populateWithSounds()
    }
    
    private func populateWithLandmarks() {
        replaceAllWith([sectionsProvider.landmarksSection.legs, sectionsProvider.landmarksSection.arms, sectionsProvider.landmarksSection.head])
    }
    private func populateWithSounds() {
        guard let soundSection = sectionsProvider.soundsSection else { return }
        replaceAllWith([soundSection])
    }
    
    private func replaceAllWith(_ sections: [DebugMenuSection]) {
        var snapshot = Snapshot()
        snapshot.appendSections(sections)
        sections.forEach { snapshot.appendItems($0.items, toSection: $0) }
        let runLoopMode = CFRunLoopMode.commonModes.rawValue
        CFRunLoopPerformBlock(CFRunLoopGetMain(), runLoopMode) { [weak dataSource] in
            dataSource?.apply(snapshot, animatingDifferences: false)
        }
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }
    
    private func removeItems(_ items: [DebugMenuItem]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.deleteItems(items)
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func reloadSection() {
        let currentSnapshot = dataSource.snapshot()
        dataSource?.apply(currentSnapshot, animatingDifferences: false)
    }
    
    private func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: DebugMenuCell.self),
                    for: indexPath) as! DebugMenuCell
                cell.item = item
                return cell
            })
        return dataSource
    }

    private func layoutCollection() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(35))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 4)
            group.interItemSpacing = .fixed(2)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 4
            section.contentInsets = NSDirectionalEdgeInsets(top: 19, leading: 2, bottom: 0, trailing: 2)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
}

// MARK: - Collection Delegate

private extension DebugCollectionMenu {
    func scrollToItem(withIndexPath indexPath: IndexPath) {
        Logger.log(indexPath.section.description + " " + indexPath.row.description, type: .all)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
}

extension DebugCollectionMenu: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? DebugMenuCell else { return }
        switch contentType {
        case .landmarks:
            cell.didSelect()
            output.send(.landmarkDidSelect(cell.item))
        case .sounds:
            cell.animateSelection()
            output.send(.soundDidSelect(cell.item))
        }
    }
}

