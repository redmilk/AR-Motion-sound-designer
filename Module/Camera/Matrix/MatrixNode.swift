//
//  MatrixNode.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation

final class MatrixNode: Hashable, Equatable {
    
    var isAnimating: Bool = false
    var id: String
        
    init() {
        id = UUID().uuidString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isAnimating)
    }
    
    static func == (lhs: MatrixNode, rhs: MatrixNode) -> Bool {
        lhs.id == rhs.id && lhs.isAnimating == rhs.isAnimating
    }
}
