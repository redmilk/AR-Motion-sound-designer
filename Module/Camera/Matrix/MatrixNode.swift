//
//  MatrixNode.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation
import UIKit

final class MatrixNode: Hashable, Equatable {
    var isGridHidden: Bool
    var painted: UIColor
    let id: String
    
    init(isGridHidden: Bool, painted: UIColor) {
        id = UUID().uuidString
        self.isGridHidden = isGridHidden
        self.painted = painted
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isGridHidden)
        hasher.combine(painted)
    }
    
    static func == (lhs: MatrixNode, rhs: MatrixNode) -> Bool {
        lhs.isGridHidden == rhs.isGridHidden && lhs.id == rhs.id && lhs.painted == rhs.painted
    }
}
