//
//  ZoneDescription.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.01.2022.
//

import Foundation

protocol EditorSoundsInteractor {
    func fillEmptyZonesWithSoundsRandomly(for mask: [SoundZone: ZoneValue])
    func fillEmptyZonesWithSoundsRandomlyFromChoosenMask(for mask: [SoundZone: ZoneValue])
    func setSoundForTouchedZoneRandomly()
    func removeAllSoundsFromMask()
}


extension EditorSoundsInteractorImpl: DatasourceForDebugProvider { }


final class EditorSoundsInteractorImpl: EditorSoundsInteractor {
    private lazy var sounds: [String] = self.debugDatasource.getSoundsSection()?.items.compactMap { $0.soundForZone } ?? []
    
    func fillEmptyZonesWithSoundsRandomly(for mask: [SoundZone: ZoneValue]) {
        let keys = mask.keys
        let values = mask.values
        let freeZones = values.filter { $0.soundName.isEmpty }
        let freeZonesTotal = freeZones.count
        
        guard let sound = sounds.randomElement() else { return  }
        
        var resultAraay: [String] = []
        var counter = 0
        
         let random = sounds.map { $0.randomElement() }
//        let rando=  rando
//        updatedZone..feeZonesupdatedZone
//        freeZones.forEach { zone in.
//            var updatedZone = zone
//
//
//            let fadf  updatedZone.soundName
//        }
    }

    func fillEmptyZonesWithSoundsRandomlyFromChoosenMask(for mask: [SoundZone: ZoneValue]) {
        
    }
    func setSoundForTouchedZoneRandomly() {
        
    }
    func removeAllSoundsFromMask() {
        
    }

    private func getRandomSound(_ count: Int) -> [String] {
       
        return []
    }
}
