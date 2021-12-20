//
//  DebugCollectionModels.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import Foundation
import MLKit

/// item
final class DebugMenuItem: Hashable, Equatable {
    
    var isSelected: Bool = false
    var landmark: PoseLandmarkType
    var id: String
        
    init(landmark: PoseLandmarkType) {
        self.landmark = landmark
        id = UUID().uuidString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(landmark)
    }
    
    static func == (lhs: DebugMenuItem, rhs: DebugMenuItem) -> Bool {
        lhs.id == rhs.id && lhs.landmark == rhs.landmark
    }
}


/// section
final class DebugMenuSection: Hashable {
    var id: String
    let items: [DebugMenuItem]
    
    init(items: [DebugMenuItem], id: String) {
        self.items = items
        self.id = id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
        hasher.combine(id)
    }

    static func == (lhs: DebugMenuSection, rhs: DebugMenuSection) -> Bool {
        lhs.id == rhs.id && lhs.items == rhs.items
    }
}


