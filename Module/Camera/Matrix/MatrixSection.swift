//
//  MatrixSection.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation

final class MatrixSection: Hashable, NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let section = MatrixSection(nodes: nodes, id: id)
        return section
    }
    
    var id: String
    let nodes: [MatrixNode]
    
    init(nodes: [MatrixNode], id: String) {
        self.nodes = nodes
        self.id = id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(nodes)
        hasher.combine(id)
    }

    static func == (lhs: MatrixSection, rhs: MatrixSection) -> Bool {
        lhs.id == rhs.id && lhs.nodes == rhs.nodes
    }
}
