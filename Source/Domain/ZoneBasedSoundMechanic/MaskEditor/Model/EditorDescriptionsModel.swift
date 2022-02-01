//
//  EditorDescriptionsModel.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 24.01.2022.
//

import Foundation

struct EditorDescription {
    let positionX: Int
    let positionY: Int
    let scaleX: Int
    let scaleY: Int
    
    var zonesTotal = 0
    let orderNumber: Int?
    let zoneTitle: String?
    let sound: String?
    let volume = 1.0
    let isForced = false
}
