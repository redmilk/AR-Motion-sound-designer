//
//  MatrixCollection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation
import Combine
import UIKit

final class MatrixCollection: NSObject { /// NSObject for collection delegate
    enum Action {
        case configure
        case replaceAllWithNewNodes([MatrixNode])
        case removeNodes([MatrixNode])
    }
    
    enum Response {
        case didPressNode(MatrixNode)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<MatrixSection, MatrixNode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<MatrixSection, MatrixNode>
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
 
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!
    private var bag = Set<AnyCancellable>()

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
        collectionView.isScrollEnabled = false
        collectionView.isPagingEnabled = false
        dataSource = buildDataSource()
        layoutCollectionAsGrid()
    }
    
    private func handleInput() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .configure:
                self.configure()
            case .replaceAllWithNewNodes(let nodes):
                self.replaceAllWithNewNodes(nodes)
            case .removeNodes(let nodes):
                self.removeNodes(nodes)
            }
        })
        .store(in: &bag)
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

    private func layoutCollectionAsGrid() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .absolute(10.0), heightDimension: .absolute(10.0))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(20))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 32)
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

