//
//  MatrixNode.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation
import UIKit

final class MatrixNode: Hashable, Equatable {
    var id: String
    
    var isNodeBelongToZone: Bool = false
    var isGridHidden: Bool
    var isAnimating: Bool = false
        
    var debugColorIfNodeBelongsToZone: UIColor?
    var colorWhenZoneSelectedInEditor: UIColor = .white
    
    init(isGridHidden: Bool, debugColorIfNodeBelongsToZone: UIColor?) {
        id = UUID().uuidString
        self.isGridHidden = isGridHidden
        self.debugColorIfNodeBelongsToZone = debugColorIfNodeBelongsToZone
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isAnimating)
        hasher.combine(debugColorIfNodeBelongsToZone)
    }
    
    static func == (lhs: MatrixNode, rhs: MatrixNode) -> Bool {
        lhs.id == rhs.id && lhs.isAnimating == rhs.isAnimating
    }
}
