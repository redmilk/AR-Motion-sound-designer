//
//  DebugCollectionModels.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import Foundation
import MLKit

// MARK: - Item
final class DebugMenuItem: Hashable, Equatable {
   var isSelected: Bool = false
   var landmark: PoseLandmarkType
   var id: String
   
   /// select sounds mode
   var soundForZone: String?
   
   init(landmark: PoseLandmarkType, soundForZone: String? = nil) {
      self.landmark = landmark
      self.soundForZone = soundForZone
      id = UUID().uuidString
   }
   
   func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(landmark)
   }
   
   static func == (lhs: DebugMenuItem, rhs: DebugMenuItem) -> Bool {
      lhs.id == rhs.id && lhs.landmark == rhs.landmark && lhs.soundForZone == rhs.soundForZone
   }
}

// MARK: - Section
final class DebugMenuSection: Hashable {
   var id: String
   var items: [DebugMenuItem]
   
   init(items: [DebugMenuItem], id: String = UUID().uuidString) {
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


