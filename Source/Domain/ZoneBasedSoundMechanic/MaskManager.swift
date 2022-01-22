//
//  MaskManager.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation

// MASK
enum MaskPreset: String, CaseIterable {
    case editor, mask64
}

final class MaskManager {
    let maskPresets: [MaskPreset: MaskProtocol]
    let forcePlayingSoundFilenames: [String: Bool] = ["": true]
    
    var shouldForceplaySoundForCurrentMask: Bool {
        return false
    }
    
    var activeMask: MaskPreset? = .editor
    var activeMaskData: MaskProtocol? {
        guard let activeMask = activeMask else { return nil }
        return maskPresets[activeMask]
    }
    
    init() {
        maskPresets = [
            .editor: EditorZoneSelection.mask,
            .mask64: Mask64Mapper(type: .sounds32).makeMask64()
        ]
    }
}
