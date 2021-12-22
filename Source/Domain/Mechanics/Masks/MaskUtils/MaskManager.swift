//
//  MaskManager.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation

// MASK
enum MaskPreset: String, CaseIterable {
    case robot//jiggle, jingleBells, robot, starWars, donda
}

class MaskManager {
    
    static let shared = MaskManager()
        
    let maskPresets: [MaskPreset: MaskProtocol]
    let forcePlayingSoundFilenames: [String: Bool] = ["": true]
    
    var shouldForceplaySoundForCurrentMask: Bool {
        return false
//        guard let activeMask = activeMask else { return true }
//        switch activeMask {
//        case .money: return false
//        case _: return true
//        }
    }
    
    var activeMask: MaskPreset = .robot
    var activeMaskData: MaskProtocol? {
        maskPresets[activeMask]
    }
    
    init() {
        maskPresets = [
            //.jiggle: JiggleMask(),
            //.cinematic: CinematicMask(),
            //.jingleBells: JingleBellMask(),
            //.money: MoneyMask(),
            .robot: RobotMask(),
            //.tabla: TablaMask()
            //.starWars: StarWarsMask(),
            //.donda: DandaMask()
        ]
    }
    
//    func mapSoundDataToBoxesAccordingToMask(_ soundBoxes: [SoundBox]) {
//        guard let mask = activeMask, let zonePresets = maskPresets[mask]?.zonePresets else { return }
//        soundBoxes.forEach {
//            let zone = $0.zone
//            guard let zoneValue = zonePresets[zone] else { return }
//            $0.updateSoundData(zone: zone, value: zoneValue)
//        }
//    }
}
